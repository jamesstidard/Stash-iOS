//
//  IdentityCreationViewController.swift
//  stash
//
//  Created by James Stidard on 10/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion
import AVFoundation

class IdentityCreationViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let entropyMachine              = EntropyMachine()
    lazy var videoCaptureSession    = AVCaptureSession()
    var gyroHarvester          : GyroHarvester!
    var accelerometerHarvester : AccelerometerHarvester!
    
    @IBOutlet weak var gyroSwitch:          UISwitch!
    @IBOutlet weak var startStopButton:     UIButton!
    @IBOutlet weak var outLabel:            UILabel!
    @IBOutlet weak var accelerometerSwitch: UISwitch!
    
    override func viewDidLoad() {
        self.accelerometerHarvester = AccelerometerHarvester(machine: self.entropyMachine)
        self.gyroHarvester          = GyroHarvester(machine: self.entropyMachine)
        entropyMachine.start()
    }
    
    @IBAction func gyroSwitchChanged(sender: UISwitch) {
        if sender.on && !self.startStopButton.selected {
            self.gyroHarvester.start()
        } else {
            self.gyroHarvester.stop()
        }
    }
    
    @IBAction func accelerometerSwitchChanged(sender: UISwitch) {
        if sender.on && !self.startStopButton.selected {
            self.accelerometerHarvester.start()
        } else {
            self.accelerometerHarvester.stop()
        }
    }
    
//    private func turnOnVideoCapture() {
////        var error: NSError?
////        
////        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
////        let input         = AVCaptureDeviceInput.deviceInputWithDevice(captureDevice, error:&error) as AVCaptureInput?
////        let output        = AVCaptureVideoDataOutput()
////        
////        let inputSucceed  = (input != nil && error == nil)
////        let canAddInput   = self.videoCaptureSession.canAddInput(input)
////        let canAddOutput  = self.videoCaptureSession.canAddOutput(output)
////        let shouldProceed = inputSucceed && canAddInput && canAddOutput
////        
////        if shouldProceed {
////            self.videoCaptureSession.addInput(input)
////            self.videoCaptureSession.addOutput(output)
////            
////            let backgroundQueue = dispatch_queue_create("com.stash.videoOutQueue", nil)
////            output.setSampleBufferDelegate(self, queue: backgroundQueue)
////            
////            self.videoCaptureSession.startRunning()
////        }
//    }
//    
//    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
//        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//        CVPixelBufferLockBaseAddress(imageBuffer, 0)
//        
//        let bufferAddress = CVPixelBufferGetBaseAddress(imageBuffer)
//        let bytesPerRow   = CVPixelBufferGetBytesPerRow(imageBuffer)
//        let height        = CVPixelBufferGetHeight(imageBuffer);
//        
//        let data = NSData(bytes: bufferAddress, length: Int(bytesPerRow * height))
//        
//        self.entropyMachine.addEntropy(data)
//        
//        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
//    }
    
    @IBAction func stopPressed(sender: UIButton) {
        
        if sender.selected {
            self.entropyMachine.start()
            if self.gyroSwitch.on { self.gyroHarvester.start() }
            if self.accelerometerSwitch.on { self.accelerometerHarvester.start() }
        } else {
            self.gyroHarvester.stop()
            self.accelerometerHarvester.stop()
            self.outLabel.text = self.entropyMachine.stop()?.description
        }
        
        sender.selected = !sender.selected
    }
}