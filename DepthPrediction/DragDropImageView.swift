//
//  DragDropImageView.swift
//  DepthPrediction
//
//  Created by Koki Ibukuro on 2019/10/09.
//  Copyright © 2019 Koki Ibukuro. All rights reserved.
//

import Cocoa
import AppKit

class DragDropImageView: NSImageView {
    
    
    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("draggingEntered")
        
        return .copy
    }

    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("draggingUpdated")
        return .copy
    }

    public override func draggingExited(_ sender: NSDraggingInfo?) {
        print("draggingExited")
    }

    public override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("prepareForDragOperation")
        return true
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("performDragOperation")
        
        let pboard = sender.draggingPasteboard
        
        guard let types = pboard.types else {
            return true
        }
        if (!types.contains(.fileURL)) {
            return true
        }
        
        guard let url = NSURL.init(from: pboard) else {
            return true
        }
        
        self.image = NSImage.init(contentsOf: url as URL)
        
        return true
    }

    public override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        print("concludeDragOperation")
    }

    public override func draggingEnded(_ sender: NSDraggingInfo) {
        print("draggingEnded")
    }

    public override func wantsPeriodicDraggingUpdates() -> Bool {
        print("wantsPeriodicDraggingUpdates")
        return true
    }
}
