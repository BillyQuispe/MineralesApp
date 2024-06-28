import UIKit

class HalfModalPresentationController: UIPresentationController {
    
    // MARK: - Presentation Setup
    
    // Define el marco de la vista presentada en el contenedor
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        return CGRect(x: 0, y: containerView.bounds.height / 2, width: containerView.bounds.width, height: containerView.bounds.height / 2)
    }
    
    // Configura la transición de presentación al inicio
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView, let presentedView = presentedView else { return }
        
        // Añade un fondo oscuro detrás del modal
        let dimmingView = UIView(frame: containerView.bounds)
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5) // Color oscuro semitransparente
        dimmingView.tag = 999 // Tag para identificar el fondo oscuro
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped))) // Agrega gesto de tap para cerrar modal
        containerView.insertSubview(dimmingView, at: 0) // Inserta el fondo oscuro debajo del modal
        
        // Establece la posición inicial del modal
        presentedView.frame = frameOfPresentedViewInContainerView
    }
    
    // Finaliza la transición de presentación
    override func presentationTransitionDidEnd(_ completed: Bool) {
        // Elimina el fondo oscuro si la presentación no se completó
        if !completed {
            containerView?.viewWithTag(999)?.removeFromSuperview()
        }
    }
    
    // MARK: - Dismissal Setup
    
    // Configura la transición de cierre al inicio
    override func dismissalTransitionWillBegin() {
        // Elimina el fondo oscuro durante la transición de cierre
        containerView?.viewWithTag(999)?.removeFromSuperview()
    }
    
    // MARK: - Layout
    
    // Ajusta el tamaño y posición de la vista presentada durante el layout
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    // MARK: - Gesture Handling
    
    // Maneja el tap en el fondo oscuro para cerrar el modal
    @objc func dimmingViewTapped() {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
}
