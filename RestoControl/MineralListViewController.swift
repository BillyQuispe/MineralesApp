import UIKit
import FirebaseDatabase
import SDWebImage
import FirebaseStorage
import FirebaseAuth

class MineralListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // Outlets
    @IBOutlet weak var listMineralesTable: UITableView!
    
    // Array para almacenar los minerales
    var minerales: [Mineral] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configurar delegate y dataSource de la tabla
        listMineralesTable.delegate = self
        listMineralesTable.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Cargar minerales cuando la vista está a punto de aparecer
        getMinerals()
    }
    
    // MARK: - UITableView DataSource Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return minerales.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "list", for: indexPath) as! MineralTableViewCell
        let mineral = minerales[indexPath.row]
        cell.configure(with: mineral)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let deletedMineral = minerales[indexPath.row]
            deleteMineralFromDatabase(mineral: deletedMineral, at: indexPath)
        }
    }
    
    // MARK: - Firebase Actions
    
    func deleteMineralFromDatabase(mineral: Mineral, at indexPath: IndexPath) {
        // Mostrar alerta para confirmar eliminación
        let alertController = UIAlertController(
            title: "Confirmar Eliminación",
            message: "¿Está seguro de que desea eliminar este mineral?",
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Eliminar", style: .destructive) { (_) in
            self.performDeletion(mineral: mineral, at: indexPath)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)

        present(alertController, animated: true, completion: nil)
    }

    func performDeletion(mineral: Mineral, at indexPath: IndexPath) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "No se pudo obtener el UID del usuario")
            return
        }
        
        let ref = Database.database().reference()
        let mineralesRef = ref.child("usuarios").child("admin").child(userUID).child("minerales").child(mineral.id)

        // Eliminar imagen asociada al mineral desde Firebase Storage
        Storage.storage().reference().child("images").child(mineral.imagenID).delete { (error) in
            if let error = error {
                print("Error deleting image: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "No se pudo eliminar la imagen.")
            } else {
                print("Image deleted successfully")

                // Eliminar el mineral de la base de datos
                mineralesRef.removeValue { (dbError, _) in
                    if let dbError = dbError {
                        print("Error deleting mineral from database: \(dbError.localizedDescription)")
                        self.showAlert(title: "Error", message: "No se pudo eliminar el mineral de la base de datos.")
                    } else {
                        print("Mineral deleted successfully")
                        // Remover el mineral del array y actualizar la tabla
                        self.minerales.remove(at: indexPath.row)
                        self.listMineralesTable.deleteRows(at: [indexPath], with: .fade)
                        self.showAlert(title: "Éxito", message: "Mineral eliminado correctamente.")
                    }
                }
            }
        }
    }
    
    // MARK: - UITableView Delegate Method
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedMineral = minerales[indexPath.row]
        performSegue(withIdentifier: "ShowDetalleMineralSegue", sender: selectedMineral)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetalleMineralSegue" {
            if let detalleMineralVC = segue.destination as? DetalleMineralViewController,
               let selectedMineral = sender as? Mineral {
                // Pasar el mineral seleccionado al detalle
                detalleMineralVC.selectedMineral = selectedMineral
                detalleMineralVC.modalPresentationStyle = .custom
                detalleMineralVC.transitioningDelegate = self
            }
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func addMineralTapped(_ sender: Any) {
        // Seguir a la pantalla de agregar nuevo mineral
        performSegue(withIdentifier: "addNewMineral", sender: nil)
    }
    
    @IBAction func logoutTapped(_ sender: Any) {
        // Cerrar sesión actual
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Firebase Realtime Database
    
    func getMinerals() {
        guard let userUID = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "No se pudo obtener el UID del usuario")
            return
        }
        
        let ref = Database.database().reference()
        let mineralesRef = ref.child("usuarios").child("admin").child(userUID).child("minerales")

        // Observadores para manejar eventos de adición y cambio en los minerales
        mineralesRef.observe(DataEventType.childAdded, with: { (snapshot) in
            self.handleMineralAdded(snapshot: snapshot)
        })
        mineralesRef.observe(DataEventType.childChanged, with: { (snapshot) in
            self.handleMineralChanged(snapshot: snapshot)
        })
    }

    // Función para manejar la adición de nuevos minerales
    func handleMineralAdded(snapshot: DataSnapshot) {
        let newMineral = Mineral()
        newMineral.id = snapshot.key
        newMineral.name = (snapshot.value as! NSDictionary)["name"] as! String
        newMineral.type = (snapshot.value as! NSDictionary)["type"] as! String
        newMineral.subtype = (snapshot.value as! NSDictionary)["subtype"] as! String
        newMineral.formula = (snapshot.value as! NSDictionary)["formula"] as! String
        newMineral.use = (snapshot.value as! NSDictionary)["use"] as! String
        
        // Obtener información de la imagen asociada al mineral, si existe
        if let imageDict = snapshot.childSnapshot(forPath: "image").value as? NSDictionary {
            newMineral.imagenID = imageDict["id"] as? String ?? ""
            newMineral.imagenURL = imageDict["url"] as? String ?? ""
        }

        // Agregar el mineral al array si no está presente
        if !self.arrayContainsID(snapshot.key) {
            self.minerales.append(newMineral)
            self.listMineralesTable.reloadData()
        }
    }

    // Función para manejar cambios en los minerales existentes
    func handleMineralChanged(snapshot: DataSnapshot) {
        let updatedMineral = Mineral()
        updatedMineral.id = snapshot.key
        updatedMineral.name = (snapshot.value as! NSDictionary)["name"] as! String
        updatedMineral.type = (snapshot.value as! NSDictionary)["type"] as! String
        updatedMineral.subtype = (snapshot.value as! NSDictionary)["subtype"] as! String
        updatedMineral.formula = (snapshot.value as! NSDictionary)["formula"] as! String
        updatedMineral.use = (snapshot.value as! NSDictionary)["use"] as! String
        
        // Obtener información de la imagen asociada al mineral, si existe
        if let imageDict = snapshot.childSnapshot(forPath: "image").value as? NSDictionary {
            updatedMineral.imagenID = imageDict["id"] as? String ?? ""
            updatedMineral.imagenURL = imageDict["url"] as? String ?? ""
        }

        // Actualizar el mineral en el array
        if let index = self.minerales.firstIndex(where: { $0.id == updatedMineral.id }) {
            self.minerales[index] = updatedMineral
            self.listMineralesTable.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }
    
    // Función para verificar si un mineral ya existe en el array
    func arrayContainsID(_ id: String) -> Bool {
        return minerales.contains { $0.id == id }
    }
    
    // Función para mostrar alertas
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

// Extensión para implementar métodos de transición personalizados
extension MineralListViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HalfModalPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
