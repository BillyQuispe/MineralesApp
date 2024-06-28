import UIKit
import FirebaseDatabase
import SDWebImage

class ListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets
    
    @IBOutlet weak var listMineralesTable: UITableView!
    @IBOutlet weak var txtBuscar: UITextField!
    
    // MARK: - Properties
    
    var minerales: [Mineral] = []

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listMineralesTable.delegate = self
        listMineralesTable.dataSource = self
        getMinerals() // Obtener minerales al cargar la vista
    }
    
    // MARK: - Data Management
    
    // Obtiene el UID del usuario predefinido (simulado)
    func obtenerUIDUsuarioPredefinido() -> String? {
        return "grYuqcrugFQToqSvqsOe7G3IYCH2" // Aquí deberías implementar la lógica real para obtener el UID
    }
    
    // Obtiene la lista de minerales desde Firebase
    func getMinerals() {
        guard let userUID = obtenerUIDUsuarioPredefinido() else {
            print("No se pudo obtener el UID del usuario predefinido")
            return
        }
        
        self.minerales.removeAll() // Limpiamos la lista actual de minerales
        
        let ref = Database.database().reference()
        let mineralesRef = ref.child("usuarios").child("admin").child(userUID).child("minerales")
        
        mineralesRef.observe(DataEventType.childAdded) { (snapshot) in
            if let mineralData = snapshot.value as? [String: Any] {
                let mineral = Mineral()
                mineral.id = snapshot.key
                mineral.name = mineralData["name"] as? String ?? ""
                mineral.formula = mineralData["formula"] as? String ?? ""
                mineral.type = mineralData["type"] as? String ?? ""
                mineral.subtype = mineralData["subtype"] as? String ?? ""
                mineral.use = mineralData["use"] as? String ?? ""
                if let imageDict = mineralData["image"] as? [String: Any] {
                    mineral.imagenID = imageDict["id"] as? String ?? ""
                    mineral.imagenURL = imageDict["url"] as? String ?? ""
                }
                self.minerales.append(mineral)
                self.listMineralesTable.reloadData()
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return minerales.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "list2", for: indexPath) as! MineralTableViewCell
        let mineral = minerales[indexPath.row]
        cell.configure(with: mineral) // Configurar la celda con el mineral correspondiente
        return cell
    }
    
    // MARK: - Actions
    
    @IBAction func btnBuscar(_ sender: Any) {
        guard let nombre = txtBuscar.text else { return }
        
        if nombre.isEmpty {
            // Si el campo de búsqueda está vacío, mostramos todos los minerales
            getMinerals()
        } else {
            buscarMineralesPorNombre(nombre)
        }
    }
    
    @IBAction func logoutBtn(_ sender: Any) {
        dismiss(animated: true, completion: nil) // Cerrar sesión
    }
    
    // MARK: - Search Functionality
    
    // Buscar minerales por nombre en Firebase
    func buscarMineralesPorNombre(_ nombre: String) {
        guard let userUID = obtenerUIDUsuarioPredefinido() else {
            print("No se pudo obtener el UID del usuario predefinido")
            return
        }
        
        self.minerales.removeAll() // Limpiamos la lista actual de minerales
        
        let ref = Database.database().reference()
        let mineralesRef = ref.child("usuarios").child("admin").child(userUID).child("minerales")
        
        let query = mineralesRef.queryOrdered(byChild: "name").queryStarting(atValue: nombre).queryEnding(atValue: "\(nombre)\u{f8ff}")
        
        query.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let mineralData = snapshot.value as? [String: Any] {
                        let mineral = Mineral()
                        mineral.id = snapshot.key
                        mineral.name = mineralData["name"] as? String ?? ""
                        mineral.formula = mineralData["formula"] as? String ?? ""
                        mineral.type = mineralData["type"] as? String ?? ""
                        mineral.subtype = mineralData["subtype"] as? String ?? ""
                        mineral.use = mineralData["use"] as? String ?? ""
                        if let imageDict = mineralData["image"] as? [String: Any] {
                            mineral.imagenID = imageDict["id"] as? String ?? ""
                            mineral.imagenURL = imageDict["url"] as? String ?? ""
                        }
                        self.minerales.append(mineral)
                    }
                }
            } else {
                self.mostrarAlerta(titulo: "Error", mensaje: "No se encontraron coincidencias para: \(nombre)", accion: "Cancelar")
            }
            self.listMineralesTable.reloadData()
        }
    }
    
    func mostrarAlerta(titulo: String, mensaje: String, accion: String) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        let btnOK = UIAlertAction(title: accion, style: UIAlertAction.Style.default, handler: nil)
        alerta.addAction(btnOK)
        present(alerta, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedMineral = minerales[indexPath.row]
        performSegue(withIdentifier: "detalleListSegue", sender: selectedMineral) // Mostrar detalle del mineral seleccionado
    }
    
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detalleListSegue" {
            if let detalleMineralVC = segue.destination as? DetalleListViewController,
               let selectedMineral = sender as? Mineral {
                detalleMineralVC.selectedMineral = selectedMineral
                detalleMineralVC.modalPresentationStyle = .custom
                detalleMineralVC.transitioningDelegate = self
            }
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension ListViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HalfModalPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
