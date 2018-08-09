//
//  ErrorCodes.swift
//  AcuantMobileSDK
//
//  Created by Tapas Behera on 7/5/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

struct ErrorCodes{
    static let ERROR_InvalidCredentials = -1
    static let ERROR_InvalidLicenseKey = -2
    static let ERROR_InvalidEndpoint = -3
    static let ERROR_InitializationNotFinished = -4
    static let ERROR_Network = -5
    static let ERROR_InvalidJson = -6
    static let ERROR_CouldNotCrop = -7
    static let ERROR_NotEnoughMemory = -8
    static let ERROR_BarcodeCaptureFailed = -9
    static let ERROR_BarcodeCaptureTimedOut = -10
    static let ERROR_BarcodeCaptureNotAuthorized = -11
    static let ERROR_LiveFaceCaptureNotAuthorized = -12
    static let ERROR_CouldNotCreateConnectInstance = -13
    static let ERROR_CouldNotUploadConnectImage = -14
    static let ERROR_CouldNotUploadConnectBarcode = -15
    static let ERROR_CouldNotGetConnectData = -16
    static let ERROR_CouldNotProcessFacialMatch = -17
    static let ERROR_CardWidthNotSet = -18
    static let ERROR_CouldNotGetHealthCardData = -19;
}
