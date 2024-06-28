import UIKit
import SDWebImage
import FirebaseDatabase
import FirebaseAuth

class DetalleMineralViewController: UIViewController {
    
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
            // Configura la vista con los datos del mineral seleccionado
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeMineralChanges()
    }

    // MARK: - Setup
    
    private func setupModalView() {
        // Configura la apariencia de la vista modal
        modalView.layer.cornerRadius = 12
        modalView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    // MARK: - Gesture Handling
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        // Maneja el gesto de deslizamiento para ocultar la vista modal
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

    // MARK: - Actions
    
    @IBAction func editTapped(_ sender: Any) {
        // Prepara y realiza la transición para editar el mineral seleccionado
        performSegue(withIdentifier: "editMineral", sender: self.selectedMineral)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Prepara la transición hacia la vista de edición del mineral
        if segue.identifier == "editMineral" {
            if let editMineralVC = segue.destination as? AddMineralViewController,
               let selectedMineral = sender as? Mineral {
                editMineralVC.mineral = selectedMineral
                // Asigna la clausura para manejar las actualizaciones en DetalleMineralViewController
                editMineralVC.didEditMineral = { editedMineral in
                    // Actualiza la interfaz con el mineral editado
                    self.updateUI(with: editedMineral)
                }
            }
        }
    }
    
    // MARK: - Firebase Observing
    
    func observeMineralChanges() {
        // Observa los cambios en los datos del mineral en Firebase
        guard let mineralId = MineralId else {
            return
        }
        guard let userUID = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "No se pudo obtener el UID del usuario")
            return
        }

        let mineralRef = databaseRef.child("usuarios").child("admin").child(userUID).child("minerales").child(mineralId)

        // Observa cambios en los datos del mineral específico
        mineralRef.observe(DataEventType.value, with: { (snapshot) in
            self.handleMineralChanges(snapshot: snapshot)
        })
    }
    
    func handleMineralChanges(snapshot: DataSnapshot) {
        // Maneja los cambios en los datos del mineral obtenidos de Firebase
        if let mineralData = snapshot.value as? [String: Any] {
            let updatedMineral = Mineral()
            updatedMineral.id = snapshot.key
            updatedMineral.name = mineralData["name"] as? String ?? ""
            updatedMineral.type = mineralData["type"] as? String ?? ""
            updatedMineral.subtype = mineralData["subtype"] as? String ?? ""
            updatedMineral.formula = mineralData["formula"] as? String ?? ""
            updatedMineral.use = mineralData["use"] as? String ?? ""
            if let imageDict = mineralData["image"] as? [String: String] {
                updatedMineral.imagenID = imageDict["id"] ?? ""
                updatedMineral.imagenURL = imageDict["url"] ?? ""
            }
            updateUI(with: updatedMineral)
        }
    }

    // MARK: - UI Update
    
    func updateUI(with mineral: Mineral) {
        // Actualiza la interfaz con los datos del mineral proporcionado
        detallBar.title = mineral.name
        typeLabel.text = mineral.type
        subtypeLabel.text = mineral.subtype
        formulaLabel.text = mineral.formula
        useLabel.text = mineral.use
        if let imageUrl = URL(string: mineral.imagenURL) {
            imageView.sd_setImage(with: imageUrl, completed: nil)
        }
    }
    
    // MARK: - Utility
    
    func showAlert(title: String, message: String) {
        // Muestra una alerta con el título y mensaje especificados
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
