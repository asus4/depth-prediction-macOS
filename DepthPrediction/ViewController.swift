//
//  ViewController.swift
//  DepthPrediction
//
//  Created by Koki Ibukuro on 2019/10/09.
//  Copyright © 2019 Koki Ibukuro. All rights reserved.
//

import Cocoa
import CoreML
import Vision


class ViewController: NSViewController {

    @IBOutlet weak var srcImageView: DragDropImageView!
    @IBOutlet weak var dstImageView: NSImageView!
    
    var model: VNCoreMLModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let model = (try? VNCoreMLModel(for: FCRN().model)) else {
            // Could not load MLModel
            // Check "FCRN.mlmodel" exists in your project
            fatalError()
        }
        self.model = model
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func startProcess(_ sender: Any) {
        print("start process!!!!")
        
        let request = VNCoreMLRequest(model: self.model, completionHandler: onVisionRequestComplete)
        request.imageCropAndScaleOption = .centerCrop
        
        guard let url = self.srcImageView.url else {
            return
        }
        
        let handler = VNImageRequestHandler(url: url, options: [:])
        try? handler.perform([request])
    }
    
    
    private func onVisionRequestComplete(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else {
            return
        }
        guard let heatmap = observations.first?.featureValue.multiArrayValue else {
            return
        }
        
        print(heatmap)
        print("convert to grayscale image")
    }
    
}

