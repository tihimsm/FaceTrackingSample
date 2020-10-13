//
//  ViewController.swift
//  FaceTrackingSample
//
//  Created by Taihei Mishima on 2020/10/13.
//  Copyright © 2020 Taihei Mishima. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var faceTracker: FaceTracker? = nil
    @IBOutlet weak var cameraView: UIView!
    
    var rectView = UIView()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.rectView.layer.borderWidth = 3
        self.view.addSubview(self.rectView)
        faceTracker = FaceTracker(
            view: self.cameraView,
            findFace: { array in
                guard let rect = array.first else { return }
                self.rectView.frame = rect
        })
    }
}

