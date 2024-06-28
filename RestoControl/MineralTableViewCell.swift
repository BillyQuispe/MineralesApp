//
//  MineralTableViewCell.swift
//  RestoControl
//
//  Created by Carlos Velasquez on 24/06/24.
//
import SDWebImage
import UIKit
import SwiftUI

class MineralTableViewCell: UITableViewCell {

   
    @IBOutlet weak var formulaLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var mineralImagenView: UIImageView!
    
    override func awakeFromNib() {
           super.awakeFromNib()
           // Configurar apariencia inicial de la celda, si es necesario
           mineralImagenView.layer.cornerRadius = mineralImagenView.frame.size.width / 2
           mineralImagenView.clipsToBounds = true
            mineralImagenView.contentMode = .scaleAspectFill
        mineralImagenView.layer.borderColor = UIColor.black.cgColor
        mineralImagenView.layer.borderWidth = 1.0

           nameLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
           formulaLabel.textColor = UIColor.gray
       }

       func configure(with mineral: Mineral) {
           nameLabel.text = mineral.name
           formulaLabel.text = mineral.formula
           // Cargar imagen usando SDWebImage u otra biblioteca de tu elección
           if let imageUrl = URL(string: mineral.imagenURL) {
               mineralImagenView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "logo.png"))
           } else {
               mineralImagenView.image = UIImage(named: "logo.png")
           }
       }

}
