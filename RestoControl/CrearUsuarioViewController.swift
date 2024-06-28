import UIKit
import FirebaseAuth
import FirebaseDatabase

class CrearUsuarioViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Configuración inicial, puede incluir preparativos adicionales.
    }

    @IBAction func btnCrearUsuario(_ sender: Any) {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            // Validación básica de campos de texto
            return
        }
        
        // Creación del usuario en Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] user, error in
            guard let self = self else { return }
            
            if let error = error {
                // Manejo de errores durante la creación de usuario
                print("Error al crear el usuario: \(error.localizedDescription)")
                // Aquí se podría mostrar una alerta al usuario
                return
            }
            
            // Éxito en la creación de usuario
            print("Usuario creado exitosamente")
            
            // Determinar el rol del usuario basado en su correo electrónico
            if let userEmail = user?.user.email {
                let userType = userEmail == "admin@empresa.com" ? "admin" : "normal"
                
                // Guardar usuario en la base de datos de Firebase
                Database.database().reference().child("usuarios").child(userType).child(user!.user.uid).child("email").setValue(user!.user.email)
            }
            
            // Alerta de éxito y transición a la siguiente vista
            let alerta = UIAlertController(title: "Creación de Usuario",
                                            message: "Usuario: \(email) se creó correctamente.",
                                            preferredStyle: .alert)
            let btnOK = UIAlertAction(title: "Aceptar", style: .default) { _ in
                // Navegar a la siguiente vista después de la creación de usuario
                self.performSegue(withIdentifier: "iniciarSegue", sender: nil)
            }
            alerta.addAction(btnOK)
            self.present(alerta, animated: true, completion: nil)
        }
    }
}
