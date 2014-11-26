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
    
    let entropyMachine           = EntropyMachine()
    lazy var motionManager       = CMMotionManager()
    lazy var videoCaptureSession = AVCaptureSession()
    
    @IBOutlet weak var gyroSwitch:      UISwitch!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var outLabel:        UILabel!
    
    override func viewDidLoad() {
        entropyMachine.start()
        self.turnOnVideoCapture()
    }
    
    @IBAction func gyroSwitchChanged(sender: UISwitch) {
        if sender.on && !self.startStopButton.selected {
            self.turnOnGyro()
        } else {
            self.motionManager.stopGyroUpdates()
        }
    }
    
    private func turnOnGyro() {
        self.motionManager.startGyroUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler: { (data, error) -> Void in
            let motionString = "\(data.rotationRate.x)\(data.rotationRate.y)\(data.rotationRate.z)"
            println(motionString)
            if let motionData = motionString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                self.entropyMachine.addEntropy(motionData)
            }
        })
    }
    
    private func turnOnVideoCapture() {
        var error: NSError?
        
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let input         = AVCaptureDeviceInput.deviceInputWithDevice(captureDevice, error:&error) as AVCaptureInput?
        let output        = AVCaptureVideoDataOutput()
        
        let inputSucceed  = (input != nil && error == nil)
        let canAddInput   = self.videoCaptureSession.canAddInput(input)
        let canAddOutput  = self.videoCaptureSession.canAddOutput(output)
        let shouldProceed = inputSucceed && canAddInput && canAddOutput
        
        if shouldProceed {
            self.videoCaptureSession.addInput(input)
            self.videoCaptureSession.addOutput(output)
            
            let backgroundQueue = dispatch_queue_create("com.stash.videoOutQueue", nil)
            output.setSampleBufferDelegate(self, queue: backgroundQueue)
            
            self.videoCaptureSession.startRunning()
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        
        let bufferAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow   = CVPixelBufferGetBytesPerRow(imageBuffer)
        let height        = CVPixelBufferGetHeight(imageBuffer);
        
        let data = NSData(bytes: bufferAddress, length: Int(bytesPerRow * height))
        
        self.entropyMachine.addEntropy(data)
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
    }
    
    @IBAction func stopPressed(sender: UIButton) {
        
        if sender.selected {
            self.entropyMachine.start()
            if self.gyroSwitch.on { self.turnOnGyro() }
        } else {
            self.motionManager.stopGyroUpdates()
            self.outLabel.text = self.entropyMachine.stop()?.description
        }
        
        sender.selected = !sender.selected
    }
}