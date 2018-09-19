//
//  CameraController.swift
//  SampleApp
//
//  Created by Tapas Behera on 7/6/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AcuantMobileSDK

class DocumentCameraController : UIViewController,DocumentCaptureDelegate{
    private let context = CIContext()
    
    var captureWaitTime = 2
    
    let vcUtil = ViewControllerUtils()
    
    var captureSession: DocumentCaptureSession!
    var lastDeviceOrientation : UIDeviceOrientation!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    let messageLayer = CATextLayer()
    
    var rightBorder : CALayer?
    var leftBorder : CALayer?
    var topBorder : CALayer?
    var bottomBorder : CALayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        let gestureRecognizer = UITapGestureRecognizer(target: self, action:  #selector (self.screenTapped (_:)))
        self.view.addGestureRecognizer(gestureRecognizer)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceDidRotate(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        self.lastDeviceOrientation = UIDevice.current.orientation
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppDelegate.AppUtility.lockOrientation(.portrait)
        startCameraView()
        vcUtil.showActivityIndicator(uiView: self.view, text: "Camera..")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
        self.videoPreviewLayer.removeFromSuperlayer()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        self.videoPreviewLayer.connection?.videoOrientation = orientation
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let connection =  self.videoPreviewLayer?.connection  {
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection
            if previewLayerConnection.isVideoOrientationSupported {
                
                switch (orientation) {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                    
                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    break
                    
                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                    break
                    
                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                    break
                    
                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func screenTapped(_ sender:UITapGestureRecognizer){
        messageLayer.string = "HOLD STEADY"
        captureSession.startCapturing(timeout: captureWaitTime)
    }
    
    func startCameraView() {
        let captureDevice: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)!
            self.view.backgroundColor = UIColor.white
            self.captureSession = Controller.getDocumentCaptureSession(delegate: self,captureDevice: captureDevice)
            self.captureSession?.startRunning()
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
                self.view.alpha = 0.3
            }, completion: nil)
    }
    
    func didStartCaptureSession() {
        vcUtil.hideActivityIndicator(uiView: self.view)
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
            self.view.alpha = 1.0
        }, completion: nil)
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.videoPreviewLayer.frame = self.view.layer.bounds
        
        // Add Semi Transparent Border
        let color = UIColor.black.withAlphaComponent(0.6)
        let shortSide = self.view.layer.bounds.width*0.9
        let longSide = shortSide/0.65
        
        let lWidth = (self.view.layer.bounds.height - longSide)/2
        let sWidth = (self.view.layer.bounds.width - shortSide)/2
        
        self.addRightBorder(color: color, width: sWidth,space:lWidth)
        self.addLeftBorder(color: color, width: sWidth,space:lWidth)
        self.addTopBorder(color: color, width: lWidth)
        self.addBottomBorder(color: color, width: lWidth)
        
        // Add Center Message
        self.messageLayer.backgroundColor = UIColor.red.cgColor
        self.messageLayer.fontSize = 35
        self.messageLayer.string = "ALIGN AND TAP"
        self.messageLayer.alignmentMode = CATextLayerAlignmentMode.center
        self.messageLayer.foregroundColor = UIColor.white.cgColor
        self.messageLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: CGFloat(Double.pi/2)));
        self.messageLayer.frame = CGRect(x: self.view.center.x-25, y: self.view.center.y-150, width: 50, height: 300)
        self.videoPreviewLayer.addSublayer(self.messageLayer)
        self.view.layer.addSublayer(self.videoPreviewLayer)
    }
    
    func documentCaptured(image: UIImage?, barcodeString: String?) {
        let rootVC : RootViewController = self.navigationController?.viewControllers[0] as! RootViewController
        rootVC.capturedBarcodeString = barcodeString
        self.navigationController?.popViewController(animated: true)
        rootVC.setCapturedImage(image: image, barcodeString: barcodeString)
    }
    
    func addRightBorder(color: UIColor, width: CGFloat,space:CGFloat) {
        rightBorder = CALayer()
        rightBorder?.borderColor = color.cgColor
        rightBorder?.borderWidth = width
        rightBorder?.frame = CGRect(x: self.view.frame.size.width-width, y: space, width: width, height: self.view.frame.size.height-2*space)
        videoPreviewLayer.addSublayer((rightBorder!))
    }
    func addLeftBorder(color: UIColor, width: CGFloat,space:CGFloat){
        leftBorder = CALayer()
        leftBorder?.borderColor = color.cgColor
        leftBorder?.borderWidth = width
        leftBorder?.frame = CGRect(x: 0, y: space, width: width, height: self.view.frame.size.height-2*space)
        videoPreviewLayer.addSublayer(leftBorder!)
    }
    func addTopBorder(color: UIColor, width: CGFloat){
        topBorder = CALayer()
        topBorder?.borderColor = color.cgColor
        topBorder?.borderWidth = width
        topBorder?.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: width)
        videoPreviewLayer?.addSublayer(topBorder!)
    }
    func addBottomBorder(color: UIColor, width: CGFloat){
        bottomBorder = CALayer()
        bottomBorder?.borderColor = color.cgColor
        bottomBorder?.borderWidth = width
        bottomBorder?.frame = CGRect(x: 0, y: self.view.frame.size.height-width, width: self.view.frame.size.width, height: width)
        videoPreviewLayer.addSublayer(bottomBorder!)
    }
    
    @objc func deviceDidRotate(notification:NSNotification)
    {
        let currentOrientation = UIDevice.current.orientation
        if(self.lastDeviceOrientation != currentOrientation){
            if(currentOrientation.isLandscape){
                if(currentOrientation == UIDeviceOrientation.landscapeLeft){
                    rotateLayer(angle: -270, layer: messageLayer)
                }else if(currentOrientation == UIDeviceOrientation.landscapeRight){
                    rotateLayer(angle: 270, layer: messageLayer)
                }
            }
            self.lastDeviceOrientation = currentOrientation;
        }
    }
    
    
    func rotateLayer(angle: Double,layer:CALayer){
        layer.transform = CATransform3DMakeRotation(CGFloat(angle / 180.0 * .pi), 0.0, 0.0, 1.0)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.topBorder?.isHidden=true
            self.bottomBorder?.isHidden=true
            self.leftBorder?.isHidden=true
            self.rightBorder?.isHidden=true
            self.videoPreviewLayer.isHidden=true
            let orient = UIApplication.shared.statusBarOrientation
            
            switch orient {
                
            case .portrait:
                
                print("Portrait")
                
            case .landscapeLeft,.landscapeRight :
                
                print("Landscape")
                
            default:
                
                print("Anything But Portrait")
            }
            
        }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.videoPreviewLayer.isHidden=false
            self.captureSession.stopRunning()
            self.startCameraView()
        })
        super.viewWillTransition(to: size, with: coordinator)
        
    }
}

