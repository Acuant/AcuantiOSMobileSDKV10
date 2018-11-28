//
//  InitializationDelegate.swift
//  AcuantMobileSDK
//
//  Created by Tapas Behera on 7/5/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

public protocol InitializationDelegate {
    func initializationFinished(error: AcuantError?);
}
