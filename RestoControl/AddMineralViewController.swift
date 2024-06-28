import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class AddMineralViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Outlets
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var typePicker: UIPickerView!
    @IBOutlet weak var subtypePicker: UIPickerView!
    @IBOutlet weak var formulaTextField: UITextField!
    @IBOutlet weak var useTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var buttonAdd: UIButton!
    @IBOutlet weak var buttonUpdate: UIButton!
    @IBOutlet weak var ButtonChangeImage: UIButton!
    
    @IBOutlet weak var tittleAddUpdateMineral: UILabel!
    @IBOutlet weak var navbarAddMineral: UINavigationItem!
    
    // MARK: - Properties
    var didEditMineral: ((Mineral) -> Void)?
    var imagePicker: UIImagePickerController!
    var mineralCategories: [String] = ["Metales", "Sulfuros", "Óxidos", "Silicatos", "Carbonatos", "Haluros"]
    var mineralSubcategories: [String: [String]] = [
        "Metales": [
            "Ferrosos",
            "No ferrosos",
            "Preciosos"
        ],
        "Sulfuros": [
            "Metálicos",
            "Sulfúreos",
            "Arseniuros"
        ],
        "Óxidos": [
            "Metálicos",
            "No Metálicos",
            "Hidróxidos"
        ],
        "Silicatos": [
            "Tectosilicatos",
            "Inosilicatos",
            "Filosilicatos"
        ],
        "Carbonatos": [
            "Calcitas",
            "Dolomitas",
            "Malaquitas"
        ],
        "Haluros": [
            "Halitas",
            "Fluoritas",
            "Sylvitas"
        ]
    ]
    
    var mineral: Mineral?  // Mineral opcional para edición
    var imageId = ""      // ID de imagen para referencia en Firebase
    var overlayView: UIView!  // Vista superpuesta para imagen
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configuración del UIImagePickerController
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        // Configuración de los UIPickerView
        typePicker.delegate = self
        typePicker.dataSource = self
        subtypePicker.delegate = self
        subtypePicker.dataSource = self
        
        // Configuración inicial de la vista según si se edita o agrega un mineral
        configureViewForMode()
    }
    
    // MARK: - Actions
    
    @IBAction func addMineralTapped(_ sender: Any) {
        guard let title = buttonAdd.title(for: .normal) else { return }
        
        if title == "Agregar" {
            guard let name = nameTextField.text, !name.isEmpty,
                  let formula = formulaTextField.text,
                  let use = useTextField.text,
                  let mineralImage = imageView.image else {
                showAlert(title: "Campos Incompletos", message: "Por favor, complete todos los campos.")
                return
            }
            
            let selectedType = mineralCategories[typePicker.selectedRow(inComponent: 0)]
            let selectedSubtype = mineralSubcategories[selectedType]?[subtypePicker.selectedRow(inComponent: 0)] ?? ""
            
            // Obtener UID del usuario actualmente autenticado
            guard let userUID = Auth.auth().currentUser?.uid else {
                showAlert(title: "Error", message: "No se pudo obtener el UID del usuario")
                return
            }
            
            uploadImageWithProgress(mineralImage) { imageUrl, error in
                if let error = error {
                    self.showAlert(title: "Error", message: "Error al cargar la imagen: \(error.localizedDescription)")
                } else if let imageUrl = imageUrl {
                    let mineralData: [String: Any] = [
                        "name": name,
                        "type": selectedType,
                        "subtype": selectedSubtype,
                        "formula": formula,
                        "use": use,
                        "image": [
                            "id": "\(self.imageId).jpg",
                            "url": imageUrl
                        ]
                    ]
                    
                    self.addMineralToDatabase(mineralData, forUserUID: userUID)
                }
            }
        } else if title == "Cancelar" {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func updateMineralTapped(_ sender: Any) {
        guard let name = nameTextField.text, !name.isEmpty,
              let formula = formulaTextField.text,
              let use = useTextField.text,
              let mineralImage = imageView.image else {
            return
        }
        
        let selectedType = mineralCategories[typePicker.selectedRow(inComponent: 0)]
        let selectedSubtype = mineralSubcategories[selectedType]?[subtypePicker.selectedRow(inComponent: 0)] ?? ""
        
        // Obtener UID del usuario actualmente autenticado
        guard let userUID = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "No se pudo obtener el UID del usuario")
            return
        }
        
        if imageView.image != nil {
            deleteImageFromStorage(imageId: mineral?.imagenID)
            uploadImageWithProgress(mineralImage) { imageUrl, error in
                if let error = error {
                    self.showAlert(title: "Error", message: "Error al cargar la imagen: \(error.localizedDescription)")
                } else if let imageUrl = imageUrl {
                    let updatedMineralData: [String: Any] = [
                        "name": name,
                        "type": selectedType,
                        "subtype": selectedSubtype,
                        "formula": formula,
                        "use": use,
                        "image": [
                            "id": "\(self.imageId).jpg",
                            "url": imageUrl
                        ]
                    ]
                    self.updateMineralInDatabase(updatedMineralData, forUserUID: userUID)
                }
            }
        } else {
            let updatedMineralData: [String: Any] = [
                "name": name,
                "type": selectedType,
                "subtype": selectedSubtype,
                "formula": formula,
                "use": use,
                "image": [
                    "id": mineral?.imagenID ?? "",
                    "url": mineral?.imagenURL ?? ""
                ]
            ]
            
            self.updateMineralInDatabase(updatedMineralData,forUserUID: userUID)
        }
    }
    
    @IBAction func selectImageTapped(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - Image Picker Delegate
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            if mineral == nil {
                overlayView.removeFromSuperview()
            }
            
            imageView.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Picker View Delegate & Data Source
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == typePicker {
            return mineralCategories.count
        } else if pickerView == subtypePicker {
            let selectedType = mineralCategories[typePicker.selectedRow(inComponent: 0)]
            return mineralSubcategories[selectedType]?.count ?? 0
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == typePicker {
            return mineralCategories[row]
        } else if pickerView == subtypePicker {
            let selectedType = mineralCategories[typePicker.selectedRow(inComponent: 0)]
            return mineralSubcategories[selectedType]?[row]
        }
        return nil
    }
    
    // MARK: - Helper Methods
    
    func uploadImageWithProgress(_ image: UIImage, completion: @escaping (String?, Error?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil, NSError(domain: "YourAppDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error al obtener datos de imagen"]))
            return
        }
        imageId = UUID().uuidString
        let storageRef = Storage.storage().reference().child("images/\(imageId).jpg")
        
        // Mostrar alerta de progreso
        let progressAlert = UIAlertController(title: "Cargando", message: "Por favor, espera...", preferredStyle: .alert)
        present(progressAlert, animated: true, completion: nil)
        
        let uploadTask = storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            // Ocultar la alerta de progreso al finalizar la carga
            progressAlert.dismiss(animated: true, completion: nil)
            
            if let error = error {
                completion(nil, error)
            } else {
                storageRef.downloadURL { (url, error) in
                    if let imageUrl = url?.absoluteString {
                        completion(imageUrl, nil)
                    } else {
                        completion(nil, error)
                    }
                }
            }
        }
        
        // Observar el progreso de la carga
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
            progressAlert.message = "Cargando... \(Int(percentComplete * 100))%"
        }
    }
    
    func addMineralToDatabase(_ mineralData: [String: Any], forUserUID userUID: String) {
        let ref = Database.database().reference()
        let mineralesRef = ref.child("usuarios").child("admin").child(userUID).child("minerales")
        
        let newMineralRef = mineralesRef.childByAutoId()
        newMineralRef.setValue(mineralData) { (error, _) in
            if let error = error {
                print("Error adding mineral to database: \(error.localizedDescription)")
            } else {
                print("Mineral added successfully")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func updateMineralInDatabase(_ mineralData: [String: Any], forUserUID userUID: String) {
        guard let mineral = mineral else {
            return
        }
        
        let ref = Database.database().reference()
        let mineralesRef = ref.child("usuarios").child("admin").child(userUID).child("minerales").child(mineral.id)
        
        mineralesRef.updateChildValues(mineralData) { (error, _) in
            if let error = error {
                print("Error updating mineral in database: \(error.localizedDescription)")
            } else {
                print("Mineral updated successfully")
                self.didEditMineral?(mineral)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func deleteImageFromStorage(imageId: String?) {
        guard let imageId = imageId else {
            return
        }
        
        let storageRef = Storage.storage().reference().child("images/\(imageId)")
        storageRef.delete { error in
            if let error = error {
                print("Error deleting image from storage: \(error.localizedDescription)")
            } else {
                print("Image deleted successfully from storage")
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func configureViewForMode() {
        if let mineral = mineral {
            // Modo edición
            nameTextField.text = mineral.name
            if let categoryIndex = mineralCategories.firstIndex(of: mineral.type),
               let subtypeIndex = mineralSubcategories[mineral.type]?.firstIndex(of: mineral.subtype) {
                typePicker.selectRow(categoryIndex, inComponent: 0, animated: false)
                subtypePicker.selectRow(subtypeIndex, inComponent: 0, animated: false)
            }
            formulaTextField.text = mineral.formula
            useTextField.text = mineral.use
            if let imageUrl = URL(string: mineral.imagenURL) {
                imageView.sd_setImage(with: imageUrl, completed: nil)
            }
            
            buttonAdd.setTitle("Cancelar", for: .normal)
            buttonAdd.backgroundColor = UIColor.red
            buttonUpdate.isHidden = false
            ButtonChangeImage.isHidden = false
            tittleAddUpdateMineral.text = "ACTUALIZAR MINERAL"
        } else {
            // Modo agregar nuevo mineral
            buttonAdd.setTitle("Agregar", for: .normal)
            buttonAdd.backgroundColor = UIColor.blue
            navbarAddMineral.title = "AGREGAR"
            tittleAddUpdateMineral.text = "NUEVO MINERAL"
            
            overlayView = UIView(frame: imageView.bounds)
            overlayView.backgroundColor = UIColor.gray
            imageView.addSubview(overlayView)
            
            let placeholderLabel = UILabel()
            placeholderLabel.text = "Insertar Imagen"
            placeholderLabel.textColor = .black
            placeholderLabel.textAlignment = .center
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
            overlayView.addSubview(placeholderLabel)
            
            placeholderLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor).isActive = true
            placeholderLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor).isActive = true
        }
    }
}
