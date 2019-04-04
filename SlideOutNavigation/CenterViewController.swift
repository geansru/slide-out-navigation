import UIKit

class CenterViewController: UIViewController {
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var creatorLabel: UILabel!
  
  var delegate: CenterViewControllerDelegate?
  
  // MARK: Button actions  
  @IBAction func kittiesTapped(_ sender: Any) {
    delegate?.toggleLeftPanel()
  }
  
  @IBAction func puppiesTapped(_ sender: Any) {
    delegate?.toggleRightPanel()
  }
}

protocol CenterViewControllerDelegate {
  func toggleLeftPanel()
  func toggleRightPanel()
  func collapseSidePanels()
}

extension CenterViewController: SidePanelViewControllerDelegate {
  func didSelectAnimal(_ animal: Animal) {
    imageView.image = animal.image
    titleLabel.text = animal.title
    creatorLabel.text = animal.creator
    delegate?.collapseSidePanels()
  }
}
