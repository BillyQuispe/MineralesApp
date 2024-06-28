

import UIKit
import SDWebImage
import FirebaseDatabase

class DetalleMineralViewController: UIViewController {

    var selectedMineral: Mineral?
    var MineralId: String?
    
    let databaseRef = Database.database().reference()

    //BAR-NAVIGATOR
    @IBOutlet weak var detallBar: UINavigationItem!
    
    //LABEL
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var subtypeLabel: UILabel!
    @IBOutlet weak var formulaLabel: UILabel!
    @IBOutlet weak var useLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var modalView: UIView!
    //@IBOutlet weak var handleArea: UIView!

    var presenter: UIViewPropertyAnimator?
    
  

    override func viewDidLoad() {
        super.viewDidLoad()

        setupModalView()
        //setupGesture()

        if let mineral = selectedMineral {
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
        observeMineralChanges()
    }

    private func setupModalView() {
        modalView.layer.cornerRadius = 12
        modalView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    /*private func setupGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        handleArea.addGestureRecognizer(panGesture)
    }*/

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

 

    /*@IBAction func cerrarVentanaTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }*/
    
    @IBAction func editTapped(_ sender: Any) {
        performSegue(withIdentifier: "editMineral", sender: self.selectedMineral)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editMineral" {
            if let editMineralVC = segue.destination as? AddMineralViewController,
               let selectedMineral = sender as? Mineral {
                editMineralVC.mineral = selectedMineral
                // Asigna la clausura para manejar las actualizaciones en DetalleDishViewController
                editMineralVC.didEditMineral = { editedMineral in
                    // Implementa aquí la lógica para actualizar la interfaz en DetalleDishViewController
                    // Puedes acceder a "editedDish" que contiene el platillo editado
                    self.updateUI(with: editedMineral)
                }
            }
        }
    }
    
    
    func observeMineralChanges() {
        guard let mineralId = MineralId else {
            return
        }

        let mineralRef = databaseRef.child("minerals").child(mineralId)

        // Observar cambios en el mineral específico
        mineralRef.observe(DataEventType.value, with: { (snapshot) in
            self.handleMineralChanges(snapshot: snapshot)
        })
    }
    
    func handleMineralChanges(snapshot: DataSnapshot) {
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

    func updateUI(with mineral: Mineral) {
            detallBar.title = mineral.name
            typeLabel.text = mineral.type
            subtypeLabel.text = mineral.subtype
            formulaLabel.text = mineral.formula
            useLabel.text = mineral.use
            if let imageUrl = URL(string: mineral.imagenURL) {
                imageView.sd_setImage(with: imageUrl, completed: nil)
            }
        }
    
}
