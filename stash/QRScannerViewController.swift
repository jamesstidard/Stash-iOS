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
    URLSessionTaskDelegate,
    SqrlLinkDataSource
{
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var shadeView: UIView!
    
    var sqrlLink: URL? {
        didSet {
            self.shadeView.isHidden = (self.sqrlLink == nil)
        }
    }
    
    
    fileprivate var captureSession = AVCaptureSession()
    fileprivate let sessionQueue   = DispatchQueue(label: "com.stidard.session-queue", attributes: [])
    fileprivate let qrCodeQueue    = DispatchQueue(label: "com.stidard.qr-output-queue", attributes: [])
    
    lazy fileprivate var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    
    // MARK: - Life Cycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.previewView.layer.addSublayer(previewLayer)
        
        sessionQueue.async {
            let output = AVCaptureMetadataOutput()
            var error: NSError?
            
            if let
                device = self.backVideoCaptureDevice(),
                let input  = AVCaptureDeviceInput(device: device, error: &error),
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
    
    fileprivate func backVideoCaptureDevice() -> AVCaptureDevice?
    {
        for device in AVCaptureDevice.devices()
        {
            if (device as AnyObject).hasMediaType(AVMediaTypeVideo) && (device as AnyObject).position == .back
            {
                return device as? AVCaptureDevice
            }
        }
        return nil
    }
    
    override func viewDidLayoutSubviews() {
        self.previewLayer.frame = self.previewView.layer.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.sessionQueue.async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        self.sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - UI Actions
    @IBAction func dismissPressed(_ sender: UIButton) {
        self.sqrlLink = nil
    }

    
    // MARK: AV QRCode Output
    func captureOutput(
        _ captureOutput: AVCaptureOutput!,
        didOutputMetadataObjects metadataObjects: [Any]!,
        from connection: AVCaptureConnection!)
    {
        // NOTE: Callback still in backgroud queue
        DispatchQueue.main.async
        {
            if self.sqrlLink != nil { return }
            
            // See if there are any QRCode's. if so take the first and see if it's a url then validate it's a sqrl-link
            // Also if we are already handling a sqrl link we dont need to worry about another
            if let
                QRCode   = metadataObjects.filter({($0 as AnyObject).type == AVMetadataObjectTypeQRCode}).first as? AVMetadataMachineReadableCodeObject,
                let sqrlLink = URL(string: QRCode.stringValue),
                sqrlLink.isValidSqrlLink
            {
                self.sqrlLink = sqrlLink
            }
        }
    }
}
