//
//  CameraPreviewView.swift
//  stash
//
//  Created by James Stidard on 22/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import AVFoundation

class CameraPreviewView: UIView {
    var session: AVCaptureSession? {
        get { return self.captureLayer.session }
        set { self.captureLayer.session = newValue}
    }
    
    var captureLayer: AVCaptureVideoPreviewLayer {
        get { return (self.layer as! AVCaptureVideoPreviewLayer) }
    }
    
    class func layerClass() -> Any.Type {
        return AVCaptureVideoPreviewLayer.self
    }
}
