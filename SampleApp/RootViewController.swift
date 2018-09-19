//
//  ViewController.swift
//  SampleApp
//
//  Created by Tapas Behera on 7/5/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import UIKit
import AcuantMobileSDK

class RootViewController: UIViewController , InitializationDelegate , IDProcessingDelegate, FacialMatchDelegate,DeleteDelegate{
    let credential = Credential()
    
    public var capturedFrontImage : UIImage?
    public var capturedBackImage : UIImage?
    public var capturedLiveFace : UIImage?
    public var capturedBarcodeString : String?
    public var capturedIDType : CardType? = CardType.ID1
    public var isProcessing : Bool = false
    public var isLiveFace : Bool = false
    public var isProcessingFacialMatch : Bool = false
    public var capturedFacialMatchResult : FacialMatchResult? = nil
    public var capturedFaceImageUrl : String? = nil
    public var isHealthCard : Bool = false
    var side = 0 // 0 : Front  1: Back
    var captureWaitTime = 0
    
    @IBOutlet var medicalCardButton: UIButton!
    @IBOutlet var idPassportButton: UIButton!
    
    @IBAction func idPassportTapped(_ sender: UIButton) {
        resetData()
        showDocumentCaptureCamera()
    }
    
    @IBAction func healthCardTapped(_ sender: UIButton) {
        resetData()
        isHealthCard = true
        showDocumentCaptureCamera()
    }
    
    func showDocumentCaptureCamera(){
        let documentCameraController = DocumentCameraController()
        documentCameraController.captureWaitTime = captureWaitTime
        AppDelegate.navigationController?.pushViewController(documentCameraController, animated: false)
    }
    
    func resetData(){
        side = 0
        captureWaitTime = 0
        isProcessing = false
        isLiveFace = false
        isHealthCard = false
        isProcessingFacialMatch = false
        capturedIDType = CardType.ID1
        capturedFrontImage = nil
        capturedBackImage = nil
        capturedLiveFace = nil
        capturedBarcodeString = nil
        capturedFaceImageUrl = nil
        capturedFacialMatchResult = nil
    }
    
    func showFacialCaptureInterface(){
        self.isProcessingFacialMatch = true
        AppDelegate.navigationController?.pushViewController(FaceLivelinessCameraController(), animated: false)
    }
    
    func cropImage(image:UIImage)->Image?{
        let croppingData = CroppingData()
        croppingData.image = image
        
        let cardAttributes = CardAttributes()
        cardAttributes.cardType = CardType.AUTO
        
        let croppingOptions = CroppingOptions()
        croppingOptions.cardAtributes = cardAttributes
        croppingOptions.imageMetricsRequired = true
        croppingOptions.isHealthCard = isHealthCard
        
        let croppedImage = Controller.crop(options: croppingOptions, data: croppingData)
        return croppedImage
    }
    
    func showResult(data:Array<String>?,front:String?,back:String?,sign:String?,face:String?){
        DispatchQueue.global().async {
            if(Controller.isFacialAllowed()){
                while(self.isProcessingFacialMatch == true){
                    sleep(1)
                }
            }
            DispatchQueue.main.async {
                self.vcUtil.hideActivityIndicator(uiView: self.view)
                let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                let resultViewController = storyBoard.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
                
                if(self.capturedFacialMatchResult != nil){
                    var dataWithFacialData = data
                    dataWithFacialData?.insert("Face matched :\(self.capturedFacialMatchResult!.isMatch)", at: 0)
                    
                    dataWithFacialData?.insert("Face Match score :\(self.capturedFacialMatchResult!.score!)", at: 0)
                    
                    if(self.isLiveFace){
                        dataWithFacialData?.insert("Is live Face : true", at: 0)
                    }else{
                        dataWithFacialData?.insert("Is live Face : false", at: 0)
                    }
                    
                    resultViewController.data = dataWithFacialData
                }else{
                    resultViewController.data = data
                }
                resultViewController.frontImageUrl = front
                resultViewController.backImageUrl = back
                resultViewController.signImageUrl = sign
                resultViewController.faceImageUrl = face
                resultViewController.username = self.credential.username
                resultViewController.password = self.credential.password
                AppDelegate.navigationController?.pushViewController(resultViewController, animated: true)
            }
            
        }
    }
    
    func showHealthCardResult(data:Array<String>?,front:UIImage?,back:UIImage?){
            DispatchQueue.main.async {
                self.vcUtil.hideActivityIndicator(uiView: self.view)
                let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                let resultViewController = storyBoard.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
                
                
                resultViewController.data = data
                
                resultViewController.front = front
                resultViewController.back = back
                AppDelegate.navigationController?.pushViewController(resultViewController, animated: true)
            }
        
    }
    public func liveFaceCaptured(image:UIImage){
        capturedLiveFace = image
        isLiveFace = true
        self.vcUtil.showActivityIndicator(uiView: self.view, text: "Processing...")
        DispatchQueue.global().async {
            while(self.isProcessing == true){
                sleep(1)
            }
            if(self.capturedFaceImageUrl != nil){
                self.isProcessingFacialMatch = true
                let loginData = String(format: "%@:%@", self.credential.username!, self.credential.password!).data(using: String.Encoding.utf8)!
                let base64LoginData = loginData.base64EncodedString()
                
                // create the request
                let url = URL(string: self.capturedFaceImageUrl!)!
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { (data, response, error) in
                    let httpURLResponse = response as? HTTPURLResponse
                    if(httpURLResponse?.statusCode == 200){
                        let downloadedImage = UIImage(data: data!)
                        
                        let facialMatchData = FacialMatchData()
                        facialMatchData.faceImageOne = downloadedImage
                        facialMatchData.faceImageTwo = self.capturedLiveFace
                        Controller.processFacialMatch(facialData: facialMatchData, delegate: self)
                    }else {
                        self.isProcessingFacialMatch = false
                        return
                    }
                    }.resume()
            }else{
                self.isProcessingFacialMatch = false
                DispatchQueue.main.async {
                    self.vcUtil.hideActivityIndicator(uiView: self.view)
                }
                
            }
        }
    }
    public func setCapturedImage(image:UIImage? , barcodeString:String?){
        self.vcUtil.showActivityIndicator(uiView: self.view, text: "Cropping...")
        if(barcodeString != nil){
            capturedBarcodeString = barcodeString
        }
        DispatchQueue.global().async {
            // Do cropping here
            let croppedImage = self.cropImage(image: image!)
            self.capturedIDType = croppedImage?.detectedCardType
            DispatchQueue.main.async {
                self.vcUtil.hideActivityIndicator(uiView: self.view)
                if(croppedImage?.error != nil){
                    CustomAlerts.displayError(message: (croppedImage?.error?.errorDescription)!)
                    return
                }
                let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                let confirmController = storyBoard.instantiateViewController(withIdentifier: "ConfirmationViewController") as! ConfirmationViewController
                if(self.side==0){
                    confirmController.side = 0
                }else{
                    confirmController.side = 1
                }
                if(barcodeString != nil){
                    confirmController.barcodeCaptured = true
                    confirmController.barcodeString = barcodeString
                }
                confirmController.image = croppedImage
                AppDelegate.navigationController?.pushViewController(confirmController, animated: true)
            }
        }
    }
    
    public func confirmImage(image:UIImage,side:Int){
        if(side==0 && capturedIDType == CardType.ID1){
            capturedFrontImage = image
            
            let alert = UIAlertController(title: "Back Side?", message: "Scan the back side of the document", preferredStyle:UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
            { action -> Void in
                self.side = 1
                if(self.isHealthCard){
                    self.captureWaitTime = 0
                }else{
                    self.captureWaitTime = 1
                }
                self.showDocumentCaptureCamera()
            })
            self.present(alert, animated: true, completion: nil)
        }else{
            if(capturedIDType == CardType.ID1){
                capturedBackImage = image
            }else{
                capturedFrontImage = image
            }
            if(isHealthCard){
                processHealthCard()
            }else{
                if(Controller.isFacialAllowed()){
                    showFacialCaptureInterface()
                }
                processId(cardType: capturedIDType!)
            }
        }
        
    }
    
    public func retryCapture(){
        showDocumentCaptureCamera()
    }
    
    let vcUtil = ViewControllerUtils()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let endPoints = Endpoints()
        endPoints.frmEndpoint = "https://frm.acuant.net/api/v1"
        endPoints.idEndpoint = "https://services.assureid.net"
        endPoints.healthInsuranceEndpoint = "https://medicscan.acuant.net/api/v1"
        
        credential.endpoints = endPoints
        credential.username = "xxxxxxx@xxxxxx.com"
        credential.password = "xxxxxxxxxx"
        credential.subscription = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        
        
        
        vcUtil.showActivityIndicator(uiView: self.view, text: "Initializing...")
        Controller.initialize(credential: credential, delegate:self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func initializationFinished(error: AcuantMobileSDK.Error?) {
        vcUtil.hideActivityIndicator(uiView: self.view)
        if(error == nil){
            medicalCardButton.isHidden = false
        }else{
            if let msg = error?.errorDescription {
                CustomAlerts.displayError(message: "\(error!.errorCode!) : " + msg)
            }
        }
    }
    
    func processHealthCard(){
        isProcessing = true
        let idData = IdData ()
        idData.frontImage = capturedFrontImage
        idData.backImage = capturedBackImage
        idData.barcodeString = capturedBarcodeString
        
        let options = IdOptions()
        options.isHealthCard = true
        vcUtil.showActivityIndicator(uiView: self.view, text: "Processing...")
        Controller.processId(imageData: idData, options: options, delegate: self)
    }
    
    func processId(cardType : CardType){
        isProcessing = true
        let idData = IdData ()
        idData.frontImage = capturedFrontImage
        idData.backImage = capturedBackImage
        idData.barcodeString = capturedBarcodeString
        
        let attributes = CardAttributes()
        attributes.cardType = cardType
        
        let options = IdOptions()
        options.isHealthCard = false
        options.cardAttributes = attributes
        vcUtil.hideActivityIndicator(uiView: self.view)
        if(Controller.isFacialAllowed() == false){
            vcUtil.showActivityIndicator(uiView: self.view, text: "Processing...")
        }
        Controller.processId(imageData: idData, options: options, delegate: self)
    }
    
    func imageProcessingFinished(result: ImageProcessingResult?) {
        if(result?.error == nil){
            if(isHealthCard){
                let healthCardResult = result as! HealthInsuranceCardResult
                let mirrored_object = Mirror(reflecting: healthCardResult)
                var dataArray = Array<String>()
                for (index, attr) in mirrored_object.children.enumerated() {
                    if let property_name = attr.label as String! {
                        if let property_value = attr.value as? String {
                            if(property_value != ""){
                                dataArray.append("\(property_name) : \(property_value)")
                            }
                        }
                    }
                }
                
                showHealthCardResult(data: dataArray, front: healthCardResult.frontImage, back: healthCardResult.backImage)
                Controller.deleteInstance(instanceId: healthCardResult.instanceID!,type:DeleteType.MedicalCard, delegate: self)
                
            }else{
                let idResult = result as! IDResult
                if(idResult.fields == nil){
                    CustomAlerts.displayError(message: "Could not extract data")
                    isProcessing = false
                    return
                }else if(idResult.fields!.dataFieldReferences == nil){
                    CustomAlerts.displayError(message: "Could not extract data")
                    isProcessing = false
                    return
                }else if(idResult.fields!.dataFieldReferences!.count==0){
                    CustomAlerts.displayError(message: "Could not extract data")
                    isProcessing = false
                    return
                }
                let fields : Array<DataFieldReference>! = idResult.fields!.dataFieldReferences!
                
                var frontImageUri: String? = nil
                var backImageUri: String? = nil
                var signImageUri: String? = nil
                var faceImageUri: String? = nil
                
                var dataArray = Array<String>()
                
                dataArray.append("Authentication Result : \(Utils.getAuthResultString(authResult: idResult.result!))")
                //var images = [String:UIImage]()
                for field in fields{
                    if(field.type == "string"){
                        dataArray.append("\(field.key!) : \(field.value!)")
                    }else if(field.type == "datetime"){
                        dataArray.append("\(field.key!) : \(Utils.dateFieldToDateString(dateStr: field.value!)!)")
                    }else if (field.key == "Photo" && field.type == "uri") {
                        faceImageUri = field.value
                        capturedFaceImageUrl = faceImageUri
                    } else if (field.key == "Signature" && field.type == "uri") {
                        signImageUri = field.value
                    }
                }
                
                for image in (idResult.images?.images!)! {
                    if (image.side == 0) {
                        frontImageUri = image.uri
                    } else if (image.side == 1) {
                        backImageUri = image.uri
                    }
                }
                isProcessing = false
                showResult(data: dataArray, front: frontImageUri, back: backImageUri, sign: signImageUri, face: faceImageUri)
                //Controller.deleteInstance(instanceId: idResult.instanceID!,type:DeleteType.ID, delegate: self)
            }
        }else{
            if let msg = result?.error?.errorDescription {
                CustomAlerts.displayError(message: msg)
            }
        }
    }
    
    func facialMatchFinished(result: FacialMatchResult?) {
        self.isProcessingFacialMatch = false
        if(result?.error == nil){
            capturedFacialMatchResult = result
        }else{
            if let msg = result?.error?.errorDescription {
                CustomAlerts.displayError(message: msg)
            }
        }
    }
    
    
    func instanceDeleted(success: Bool) {
        print()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

