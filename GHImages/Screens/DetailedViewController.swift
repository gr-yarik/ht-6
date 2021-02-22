//
//  DetailedViewController.swift
//  GHImages
//
//  Created by Yaroslav Hrytsun on 21.02.2021.
//

import UIKit

class DetailedViewController: UIViewController {
    
    var image: UIImage?
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
    }
}
