//
//  QRCodeScannerViewController.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import AVFoundation

protocol QRCodeScannerDelegate {
    func onSuccess(qrCode: String)
    func onFailure(error: Error)
}

class QRCodeScannerViewController: UIViewController {

    //  MARK: Properties
    var delegate: QRCodeScannerDelegate?
    var session: AVCaptureSession
    @IBOutlet weak var previewView: UIView?
    
    
    //  MARK: Lifecycle
    required init?(coder: NSCoder) {
        session = AVCaptureSession()
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScanner()
    }
    
    deinit {
        session.stopRunning()
    }
    
    
    //  MARK: Private - setup
    
    /// Initializes necessary components for AVCaptureSession
    func setupScanner() {
        let failureError = NSError(domain: "com.forgerock.authenticator.sampleapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to initiate Scanner view."])
        
        guard let device = AVCaptureDevice.default(for: .video) else {
            self.dismiss(animated: true) {
                self.delegate?.onFailure(error: failureError)
            }
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: device)
        } catch let error {
            self.dismiss(animated: true) {
                self.delegate?.onFailure(error: error)
            }
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        else {
            self.dismiss(animated: true) {
                self.delegate?.onFailure(error: failureError)
            }
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }
        else {
            self.dismiss(animated: true) {
                self.delegate?.onFailure(error: failureError)
            }
            return
        }
        
        guard let previewView = previewView else {
            self.dismiss(animated: true) {
                self.delegate?.onFailure(error: failureError)
            }
            return
        }
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.frame = previewView.layer.bounds
        layer.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(layer)
        session.startRunning()
    }
        
    
    //  MARK: - IBAction
    @IBAction func cancel(sender: UIButton) {
        self.dismiss(animated: true)
    }
}


extension QRCodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        session.stopRunning()
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject, let qrCode = readableObject.stringValue else {
                return
            }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            self.dismiss(animated: true) {
                self.delegate?.onSuccess(qrCode: qrCode)
            }
        }
    }
}
