//
//  DetalleListViewController.swift
//  RestoControl
//
//  Created by Carlos Velasquez on 24/06/24.
//

import UIKit
import SDWebImage
import FirebaseDatabase

import UIKit

class DetalleListViewController: UIViewController {

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

}
