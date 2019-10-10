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
        
        let request = VNCoreMLRequest(model: self.model, completionHandler: onVisionRequestComplete)
        request.imageCropAndScaleOption = .centerCrop
        
        guard let url = self.srcImageView.url else {
            print("No source image")
            return
        }
        
        let handler = VNImageRequestHandler(url: url, options: [:])
        try? handler.perform([request])
    }
    
    @IBAction func onExportDepth(_ sender: Any) {
        guard let srcUrl = self.srcImageView.url,
              let image = self.dstImageView.image else {
            return
        }
        
        let panel = NSSavePanel()
        let filename = srcUrl.deletingPathExtension().lastPathComponent
        panel.nameFieldStringValue = "\(filename)_depth.png"
        panel.directoryURL = srcUrl.deletingLastPathComponent()
        
        panel.begin { (result) in
            if result.rawValue != NSApplication.ModalResponse.OK.rawValue {
                return
            }
            guard let url = panel.url else {
                return
            }
            self.saveToPng(image: image, url: url)
        }
    }
    
    @IBAction func onExportTrimed(_ sender: Any) {
        guard let srcUrl = self.srcImageView.url,
              let image = self.srcImageView.image else {
            return
        }
        
        let targetAspect: CGFloat = 4.0 / 3.0
        let imageAspect = image.size.width / image.size.height
        
        let rect: CGRect
        if targetAspect < imageAspect {
            let w = image.size.height * targetAspect
            rect = CGRect(x: (image.size.width - w) / 2, y: 0, width: w, height: image.size.height)
        } else {
            let h = image.size.width / targetAspect
            rect = CGRect(x: 0, y: (image.size.height - h) / 2, width: image.size.width, height: h)
        }
        
        print(targetAspect, imageAspect, image.size, rect)
        
        let trimedImage = image.trim(rect: rect)
        
        print(trimedImage)
        
        let panel = NSSavePanel()
        let filename = srcUrl.deletingPathExtension().lastPathComponent
        panel.nameFieldStringValue = "\(filename).png"
        panel.directoryURL = srcUrl.deletingLastPathComponent()
        
        panel.begin { (result) in
            if result.rawValue != NSApplication.ModalResponse.OK.rawValue {
                return
            }
            guard let url = panel.url else {
                return
            }
            self.saveToPng(image: trimedImage, url: url)
        }
    }
    
    private func saveToPng(image:NSImage, url: URL) {
        // https://stackoverflow.com/questions/17507170/how-to-save-png-file-from-nsimage-retina-issues
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: [:]) else {
            print("no cg image")
            return
        }
        let newRep = NSBitmapImageRep.init(cgImage: cgImage)
        newRep.size = NSSize(width: cgImage.width, height: cgImage.height)
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
        
        let result = NSImage(size: size)
        result.lockFocus()
        self.draw(in: dstRect)
        result.unlockFocus()
        return result
    }
    
    func trim(rect: CGRect) -> NSImage {
        
        let result = NSImage(size: rect.size)
        result.lockFocus()
        
        let destRect = CGRect(origin: .zero, size: result.size)
        self.draw(in: destRect, from: rect, operation: .copy, fraction: 1.0)
        result.unlockFocus()
        return result
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
