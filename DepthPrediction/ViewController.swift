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
import CoreGraphics


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
    
    @IBAction func onExport(_ sender: Any) {
        guard let srcUrl = self.srcImageView.url else {
            return
        }
        
        let panel = NSSavePanel()
        let filename = srcUrl.deletingPathExtension().lastPathComponent
        panel.nameFieldStringValue = "\(filename)_depth.png"
        panel.directoryURL = srcUrl.deletingLastPathComponent()
        
        panel.begin { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let image = self.dstImageView.image,
                      let url = panel.url else {
                    return
                }
                self.saveToPng(image: image, url: url)
            }
        }
    }
    
    private func saveToPng(image:NSImage, url: URL) {
        // TO png
        // https://stackoverflow.com/questions/17507170/how-to-save-png-file-from-nsimage-retina-issues
        guard let image = self.dstImageView.image?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }
        let newRep = NSBitmapImageRep.init(cgImage: image)
        newRep.size = NSSize(width: image.width, height: image.height)
        guard let data = newRep.representation(using: .png, properties: [:]) else {
            return
        }
        try? data.write(to: url)
    }
    
    private func onVisionRequestComplete(request: VNRequest, error: Error?) {
        
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation],
              let depth = observations.first?.featureValue.multiArrayValue else {
            return
        }
        
        // Find min max
        let minmax = depth.minmaxValue()
        
        // Invert min max
        guard let image = depth.cgImage(min: minmax.1, max: minmax.0),
              let size = self.srcImageView.image?.size else {
            return
        }
        
        let resizeImage = NSImage.init(cgImage: image, size: size).resize(size: size)
        self.dstImageView.image = resizeImage
    }
}

extension NSImage {
    func resize(size: CGSize) -> NSImage {
        let dstRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        self.draw(in: dstRect)
        newImage.unlockFocus()
        newImage.size = size
        return NSImage(data: newImage.tiffRepresentation!)!
    }
}

extension MLMultiArray {

    public func minmaxValue() -> (Double, Double) {
        
        if(self.dataType != .double) {
            fatalError("only double is supported format")
        }
        
        var minValue = Double.greatestFiniteMagnitude
        var maxValue = -Double.greatestFiniteMagnitude
        
        // Slow version
        for i in 0..<self.count {
            let n = self[i].doubleValue
            minValue = min(n, minValue)
            maxValue = max(n, maxValue)
        }
        
        return (minValue, maxValue)
    }
}
