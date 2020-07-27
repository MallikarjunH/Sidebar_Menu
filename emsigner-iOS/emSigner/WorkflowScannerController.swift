//
//  ViewController.swift
//  demo
//
//  Created by Denis Martin on 28/06/2015.
//  Copyright (c) 2015 iRLMobile. All rights reserved.
//

import UIKit
import Foundation
import IRLDocumentScanner;

@objc class WorkflowScannerController : UIViewController, IRLScannerViewControllerDelegate {
    
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var imageView:  UIImageView!
    
    
    var imageForUploadApi: UploadDocuments = UploadDocuments()

    // MARK: User Actions

    override func viewDidLoad() {
           super.viewDidLoad()
           

       }
    
    override func viewDidAppear(_ animated: Bool) {
           super.viewDidAppear(animated)
              
              let scanner = IRLScannerViewController.standardCameraView(with: self)
                 // scanner.showControls = true
                  scanner.showAutoFocusWhiteRectangle = true
                  present(scanner, animated: true, completion: nil)

          }
    
    
//    @IBAction func scan(_ sender: AnyObject) {
//        let scanner = IRLScannerViewController.standardCameraView(with: self)
//        scanner.showControls = true
//        scanner.showAutoFocusWhiteRectangle = true
//        present(scanner, animated: true, completion: nil)
//    }
    
    // MARK: IRLScannerViewControllerDelegate
    func pageSnapped(_ page_image: UIImage, from controller: IRLScannerViewController) {
        
       // self.presentingViewController?.dismiss(animated: true, completion: nil)
        //self.imageForUploadApi.ima
        self.presentingViewController?.dismiss(animated: true) { () -> Void in
            //self.imageView.image = page_image
        }
    }
        
    func cameraViewWillUpdateTitleLabel(_ cameraView: IRLScannerViewController) -> String? {
        
        var text = ""
        switch cameraView.cameraViewType {
        case .normal:           text = text + "NORMAL"
        case .blackAndWhite:    text = text + "B/W-FILTER"
        case .ultraContrast:    text = text + "CONTRAST"
        }
        
        switch cameraView.detectorType {
        case .accuracy:         text = text + " | Accuracy"
        case .performance:      text = text + " | Performance"
        }
        
        return text
    }

    func didCancel(_ cameraView: IRLScannerViewController) {
        cameraView.dismiss(animated: true){ ()-> Void in
            NSLog("Cancel pressed");
           }
    }
    
}
