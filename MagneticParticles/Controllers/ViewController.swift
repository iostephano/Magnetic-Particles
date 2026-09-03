//
//  ViewController.swift
//  MagneticParticles
//
//  Created by Stephano Portella on 04/06/25.
//

import UIKit

class ViewController: UIViewController {
    private var magneticView: MagneticParticlesView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        magneticView = MagneticParticlesView(frame: view.bounds)
        magneticView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(magneticView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        magneticView.frame = view.bounds
    }
}
