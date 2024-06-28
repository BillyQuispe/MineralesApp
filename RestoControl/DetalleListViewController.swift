import UIKit
import SDWebImage
import FirebaseDatabase

class DetalleListViewController: UIViewController {

    // MARK: - Properties

    var selectedMineral: Mineral?
    var MineralId: String?
    let databaseRef = Database.database().reference()
    var presenter: UIViewPropertyAnimator?

    // MARK: - Outlets

    @IBOutlet weak var detallBar: UINavigationItem!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var subtypeLabel: UILabel!
    @IBOutlet weak var formulaLabel: UILabel!
    @IBOutlet weak var useLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var modalView: UIView! // Vista modal para edición

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupModalView()

        if let mineral = selectedMineral {
            // Configurar la vista con los datos del mineral seleccionado
            detallBar.title = mineral.name
            typeLabel.text = mineral.type
            subtypeLabel.text = mineral.subtype
            formulaLabel.text = mineral.formula
            useLabel.text = mineral.use
            if let imageUrl = URL(string: mineral.imagenURL) {
                imageView.sd_setImage(with: imageUrl, completed: nil)
            }
            MineralId = mineral.id
        }
    }

    // MARK: - Setup

    private func setupModalView() {
        // Configurar la apariencia de la vista modal
        modalView.layer.cornerRadius = 12
        modalView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    // MARK: - Gesture Handling

    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: modalView)

        switch recognizer.state {
        case .began:
            presenter = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.8) {
                self.modalView.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            presenter?.startAnimation()
            presenter?.pauseAnimation()
        case .changed:
            presenter?.fractionComplete = translation.y / 200
        case .ended:
            let velocity = recognizer.velocity(in: modalView).y

            if velocity > 0 {
                presenter?.addAnimations {
                    self.modalView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
                }
                presenter?.addCompletion { _ in
                    self.dismiss(animated: false, completion: nil)
                }
            } else {
                presenter?.isReversed = true
            }

            presenter?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        default:
            break
        }
    }

}
