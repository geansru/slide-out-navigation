import UIKit
import QuartzCore

enum SlideOutState {
  case bothCollapsed
  case leftPanelExpanded
  case rightPanelExpanded
}

class ContainerViewController: UIViewController {
  
  private var centerNavigationController: UINavigationController!
  private var centerViewController: CenterViewController!
  
  private var currentState: SlideOutState = .bothCollapsed {
    didSet {
      let shouldShowShadow = currentState != .bothCollapsed
      showShadowForCenterViewController(shouldShowShadow)
    }
  }
  
  private var leftViewController: SidePanelViewController?
  private var rightViewController: SidePanelViewController?
  
  private let centerPanelExpandedOffset: CGFloat = 90
  
  override func viewDidLoad() {
    super.viewDidLoad()
    applyInitialConfiguration()
  }
  
  private func applyInitialConfiguration() {
    centerViewController = UIStoryboard.centerViewController()
    centerViewController.delegate = self
    
    centerNavigationController = UINavigationController(rootViewController: centerViewController)
    view.addSubview(centerNavigationController.view)
    addChild(centerNavigationController)
    
    centerNavigationController.didMove(toParent: self)
    
    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    centerNavigationController.view.addGestureRecognizer(panGestureRecognizer)
  }
  
}

private extension UIStoryboard {
  static func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: Bundle.main) }
  
  static func leftViewController() -> SidePanelViewController? {
    return mainStoryboard().instantiateViewController(withIdentifier: "LeftViewController") as? SidePanelViewController
  }
  
  static func rightViewController() -> SidePanelViewController? {
    return mainStoryboard().instantiateViewController(withIdentifier: "RightViewController") as? SidePanelViewController
  }
  
  static func centerViewController() -> CenterViewController? {
    return mainStoryboard().instantiateViewController(withIdentifier: "CenterViewController") as? CenterViewController
  }
}

// MARK: CenterViewController delegate

extension ContainerViewController: CenterViewControllerDelegate {
  func toggleLeftPanel() {
    let notAlreadyExpanded = (currentState != .leftPanelExpanded)
    
    if notAlreadyExpanded {
      addLeftPanelViewController()
    }
    
    animateLeftPanel(shouldExpand: notAlreadyExpanded)
  }
  
  func toggleRightPanel() {
    let notAlreadyExpanded = (currentState != .rightPanelExpanded)
    
    if notAlreadyExpanded {
      addRightPanelViewController()
    }
    
    animateRightPanel(shouldExpand: notAlreadyExpanded)
  }
  
  func collapseSidePanels() {
    switch currentState {
    case .rightPanelExpanded:
      toggleRightPanel()
    case .leftPanelExpanded:
      toggleLeftPanel()
    case .bothCollapsed:
      break
    }
  }
  
  // MARK: - Private methods
  
  // MARK: toggle left panel implementation
  
  private func addLeftPanelViewController() {
    guard leftViewController == nil else { return }
    
    if let leftViewController = UIStoryboard.leftViewController() {
      leftViewController.animals = Animal.allCats()
      addChildSidePanelController(leftViewController)
      self.leftViewController = leftViewController
    }
  }
  
  private func addChildSidePanelController(_ sidePanelController: SidePanelViewController) {
    view.insertSubview(sidePanelController.view, at: 0)
    
    addChild(sidePanelController)
    sidePanelController.didMove(toParent: self)
    sidePanelController.delegate = centerViewController
  }
  
  private func animateLeftPanel(shouldExpand: Bool) {
    if shouldExpand {
      currentState = .leftPanelExpanded
      let targetPosition = centerNavigationController.view.frame.width - centerPanelExpandedOffset
      animateCenterPanelXPosition(targetPosition: targetPosition)
    }
    else {
      animateCenterPanelXPosition(targetPosition: 0) { [weak self] _ in
        guard let `self` = self else { return }
        self.currentState = .bothCollapsed
        self.leftViewController?.view.removeFromSuperview()
        self.leftViewController = nil
      }
    }
  }
  
  private func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)? = nil) {
    let animations: () -> Void = { [weak self] in
      self?.centerNavigationController.view.frame.origin.x = targetPosition
    }
    UIView.animate(withDuration: 0.5,
                   delay: 0,
                   usingSpringWithDamping: 0.8,
                   initialSpringVelocity: 0,
                   options: .curveEaseInOut,
                   animations: animations,
                   completion: completion)
  }

  func showShadowForCenterViewController(_ shouldShowShadow: Bool) {
    if shouldShowShadow {
      centerNavigationController.view.layer.shadowOpacity = 0.8
    } else {
      centerNavigationController.view.layer.shadowOpacity = 0.0
    }
  }
  
  // MARK: toggle right panel implementation

  func addRightPanelViewController() {
    guard rightViewController == nil else { return }
    
    if let rightViewController = UIStoryboard.rightViewController() {
      rightViewController.animals = Animal.allDogs()
      addChildSidePanelController(rightViewController)
      self.rightViewController = rightViewController
    }
  }
  
  func animateRightPanel(shouldExpand: Bool) {
    if shouldExpand {
      currentState = .rightPanelExpanded
      let targetPosition = -centerNavigationController.view.frame.width + centerPanelExpandedOffset
      animateCenterPanelXPosition(targetPosition: targetPosition)
    } else {
      animateCenterPanelXPosition(targetPosition: 0) { _ in
        self.currentState = .bothCollapsed
        self.rightViewController?.view.removeFromSuperview()
        self.rightViewController = nil
      }
    }
  }
  
}

// MARK: Gesture recognizer

extension ContainerViewController: UIGestureRecognizerDelegate {
  @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
    let gestureIsDraggingFromLeftToRight = (recognizer.velocity(in: view).x > 0)
    
    switch recognizer.state {
    case .began:
      if currentState == .bothCollapsed {
        if gestureIsDraggingFromLeftToRight {
          addLeftPanelViewController()
        } else {
          addRightPanelViewController()
        }
        showShadowForCenterViewController(true)
      }
      
    case .changed:
      if let rview = recognizer.view {
        rview.center.x = rview.center.x + recognizer.translation(in: view).x
        recognizer.setTranslation(CGPoint.zero, in: view)
      }
      
    case .ended:
      if let _ = leftViewController,
        let rview = recognizer.view {
        // animate the side panel open or closed based on whether the view
        // has moved more or less than halfway
        let hasMovedGreaterThanHalfway = rview.center.x > view.bounds.size.width
        animateLeftPanel(shouldExpand: hasMovedGreaterThanHalfway)
      } else if let _ = rightViewController,
        let rview = recognizer.view {
        let hasMovedGreaterThanHalfway = rview.center.x < 0
        animateRightPanel(shouldExpand: hasMovedGreaterThanHalfway)
      }
      
    default:
      break
    }
  }
  
}
