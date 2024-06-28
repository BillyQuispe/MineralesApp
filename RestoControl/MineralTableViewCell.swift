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
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Configuración de la apariencia inicial de la celda
        self.layer.cornerRadius = 20
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.lightGray.cgColor
        
        self.contentView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        // Configuración específica para la imagen del mineral
        mineralImagenView.layer.cornerRadius = mineralImagenView.frame.size.width / 2
        mineralImagenView.clipsToBounds = true
        mineralImagenView.contentMode = .scaleAspectFill
        mineralImagenView.layer.borderColor = UIColor.black.cgColor
        mineralImagenView.layer.borderWidth = 1.0
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 20.0) // Estilo de fuente para el nombre del mineral
        formulaLabel.textColor = UIColor.gray // Color de texto para la fórmula del mineral
    }
    
    // MARK: - Configuration
    
    func configure(with mineral: Mineral) {
        nameLabel.text = mineral.name // Asigna el nombre del mineral a la etiqueta correspondiente
        formulaLabel.text = mineral.formula // Asigna la fórmula del mineral a la etiqueta correspondiente
        
        // Carga la imagen del mineral usando SDWebImage (o la biblioteca que prefieras)
        if let imageUrl = URL(string: mineral.imagenURL) {
            mineralImagenView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "logo.png"))
        } else {
            mineralImagenView.image = UIImage(named: "logo.png") // Establece una imagen de placeholder si no hay URL válida
        }
    }
}

