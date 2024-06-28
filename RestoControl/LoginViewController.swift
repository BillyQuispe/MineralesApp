//

//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnAccess: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        guard let email = txtEmail.text, let password = txtPassword.text else {
                   return
               }
               
               Auth.auth().signIn(withEmail: email, password: password) { [weak self] (user, error) in
                   guard let self = self else { return }
                   
                   if let error = error {
                       print("Se presentó el siguiente error al iniciar sesión: \(error.localizedDescription)")
                       
                       // Mostrar alerta si las credenciales son incorrectas
                       let alerta = UIAlertController(title: "Inicio de sesión", message: "Credenciales incorrectas", preferredStyle: .alert)
                       
                       // Botón para redirigir a la pantalla de registro
                       let btnCrear = UIAlertAction(title: "Crear", style: .default) { (_) in
                           self.performSegue(withIdentifier: "registrarSegue", sender: nil)
                       }
                       
                       // Botón para cancelar
                       let btnCancelar = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
                       
                       alerta.addAction(btnCrear)
                       alerta.addAction(btnCancelar)
                       
                       self.present(alerta, animated: true, completion: nil)
                   } else {
                       print("Inicio de sesión exitoso")
                       
                       // Redireccionar según el correo electrónico del usuario
                       if email == "admin@empresa.com" {
                           self.performSegue(withIdentifier: "adminSegue", sender: nil)
                       } else {
                           self.performSegue(withIdentifier: "userSegue", sender: nil)
                       }
                   }
     }
     
    
    
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
}

