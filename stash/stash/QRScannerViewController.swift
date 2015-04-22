//
//  QRScannerViewController.swift
//  stash
//
//  Created by James Stidard on 25/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import AVFoundation


class QRScannerViewController: UIViewController,
    AVCaptureMetadataOutputObjectsDelegate,
    NSURLSessionTaskDelegate
{
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var shadeView: UIView!
    
    weak var delegate: SqrlLinkRepository?
    var sqrlLink: NSURL? {
        set {
            self.delegate?.sqrlLink = newValue
            self.shadeView.hidden   = (self.sqrlLink == nil) ? true : false
        }
        get {
            return self.delegate?.sqrlLink
        }
    }
    
    
    private var captureSession = AVCaptureSession()
    private let sessionQueue   = dispatch_queue_create("com.stidard.session-queue", DISPATCH_QUEUE_SERIAL)
    private let qrCodeQueue    = dispatch_queue_create("com.stidard.qr-output-queue", nil)
    
    lazy private var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    
    // MARK: - Life Cycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.previewView.layer.addSublayer(previewLayer)
        
        dispatch_async(sessionQueue) {
            let output = AVCaptureMetadataOutput()
            var error: NSError?
            
            if let
                device = self.backVideoCaptureDevice(),
                input  = AVCaptureDeviceInput(device: device, error: &error)
            where
                error == nil &&
                self.captureSession.canAddInput (input) &&
                self.captureSession.canAddOutput(output)
            {
                self.captureSession.addInput (input)
                self.captureSession.addOutput(output)
                
                output.setMetadataObjectsDelegate(self, queue: self.qrCodeQueue)
                output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            }
        }
    }
    
    private func backVideoCaptureDevice() -> AVCaptureDevice?
    {
        for device in AVCaptureDevice.devices()
        {
            if device.hasMediaType(AVMediaTypeVideo) && device.position == .Back
            {
                return device as? AVCaptureDevice
            }
        }
        return nil
    }
    
    override func viewDidLayoutSubviews() {
        self.previewLayer.frame = self.previewView.layer.bounds
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        dispatch_async(self.sessionQueue) {
            self.captureSession.startRunning()
        }
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        dispatch_async(self.sessionQueue) {
            self.captureSession.stopRunning()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - UI Actions
    @IBAction func dismissPressed(sender: UIButton) {
        self.sqrlLink = nil
    }

    
    // MARK: AV QRCode Output
    func captureOutput(
        captureOutput: AVCaptureOutput!,
        didOutputMetadataObjects metadataObjects: [AnyObject]!,
        fromConnection connection: AVCaptureConnection!)
    {
        // NOTE: Callback still in backgroud queue
        dispatch_async(dispatch_get_main_queue())
        {
            if self.sqrlLink != nil { return }
            
            // See if there are any QRCode's. if so take the first and see if it's a url then validate it's a sqrl-link
            // Also if we are already handling a sqrl link we dont need to worry about another
            if let
                QRCode   = metadataObjects.filter({$0.type == AVMetadataObjectTypeQRCode}).first as? AVMetadataMachineReadableCodeObject,
                sqrlLink = NSURL(string: QRCode.stringValue)
                where
                sqrlLink.isValidSqrlLink
            {
                self.sqrlLink = sqrlLink
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
