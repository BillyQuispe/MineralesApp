import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    // Outlets para los campos de texto y botón de acceso
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnAccess: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Configuración inicial de la vista
    }
    
    // Acción del botón "Iniciar Sesión"
    @IBAction func signInButtonTapped(_ sender: Any) {
        // Obtener el email y contraseña ingresados
        guard let email = txtEmail.text, let password = txtPassword.text else {
            return
        }
        
        // Autenticación con Firebase
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (user, error) in
            guard let self = self else { return }
            
            if let error = error {
                // Mostrar mensaje de error si las credenciales son incorrectas
                print("Error al iniciar sesión: \(error.localizedDescription)")
                
                // Alerta para manejar el error de credenciales incorrectas
                let alert = UIAlertController(title: "Inicio de sesión",
                                              message: "Credenciales incorrectas",
                                              preferredStyle: .alert)
                
                // Acción para redirigir a la pantalla de registro
                let actionCreate = UIAlertAction(title: "Crear", style: .default) { (_) in
                    self.performSegue(withIdentifier: "registrarSegue", sender: nil)
                }
                
                // Acción para cancelar
                let actionCancel = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
                
                alert.addAction(actionCreate)
                alert.addAction(actionCancel)
                
                self.present(alert, animated: true, completion: nil)
            } else {
                // Inicio de sesión exitoso
                print("Inicio de sesión exitoso")
                
                // Redireccionar según el tipo de usuario
                if email == "admin@empresa.com" {
                    self.performSegue(withIdentifier: "adminSegue", sender: nil)
                } else {
                    self.performSegue(withIdentifier: "userSegue", sender: nil)
                }
            }
        }
    }
    
    // Función para mostrar alertas genéricas
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
