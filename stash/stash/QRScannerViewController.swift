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
    
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var captureDevice:     AVCaptureDevice?
    private var _captureSession:   AVCaptureSession?
    private var captureSession:    AVCaptureSession {
        if _captureSession == nil {
            _captureSession = AVCaptureSession()
        }
        return _captureSession!
    }
    
    
    
    // MARK: - Life Cycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.captureSession.sessionPreset = AVCaptureSessionPresetLow
        for device in AVCaptureDevice.devices()
        {
            if device.hasMediaType(AVMediaTypeVideo) && device.position == .Back
            {
                self.captureDevice = device as? AVCaptureDevice
                return
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.startSession()
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        super.viewDidDisappear(animated)
        self.stopSession()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - UI Actions
    @IBAction func dismissPressed(sender: UIButton)
    {
        self.sqrlLink = nil
    }
    
    
    // MARK: - AV Life Cycle
    private func startSession()
    {
        var error: NSError?
        let output = AVCaptureMetadataOutput()
        
        if let
            input = AVCaptureDeviceInput(device: self.captureDevice, error: &error)
        where
            error == nil &&
            self.captureSession.canAddInput (input) &&
            self.captureSession.canAddOutput(output)
        {
            self.captureSession.addInput (input)
            self.captureSession.addOutput(output)
            
            let dispatchQueue = dispatch_queue_create("com.stidard.scanner-output-queue", nil)
            output.setMetadataObjectsDelegate(self, queue: dispatchQueue)
            output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
            self.videoPreviewLayer               = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.videoPreviewLayer?.frame        = self.previewView.layer.bounds
            self.previewView.layer.addSublayer(self.videoPreviewLayer)
            
            self.captureSession.startRunning()
        }
        else
        {
            NSLog("Unable to add Input to capture session: \n\(self.captureSession)\n with device: \n\(self.captureDevice)")
        }
    }
    
    private func stopSession()
    {
        self.captureSession.stopRunning()
        self.videoPreviewLayer?.removeFromSuperlayer()
        self._captureSession = nil
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
