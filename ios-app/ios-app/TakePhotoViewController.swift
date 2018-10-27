//
//  TakePhotoViewController.swift
//  ios-app
//
//  Created by 三上大河 on 2018/10/27.
//  Copyright © 2018年 三上大河. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class TakePhotoViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    var captureSession = AVCaptureSession()
    var backCamera:AVCaptureDevice?
    var frontCamera:AVCaptureDevice?
    var currentCamera:AVCaptureDevice?
    var photoOutput:AVCapturePhotoOutput?
    var cameraPreviewlayer:AVCaptureVideoPreviewLayer?
    var image:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // カメラの許可を出す
        PHPhotoLibrary.requestAuthorization { (status) in
            switch(status) {
            case .authorized:
                print("許可")
            case .denied:
                print("denied")
            case .notDetermined:
                print("notDetermined")
            case .restricted:
                print("restricted")
            }
        }
        
        setUpCaptureSession()
        setUpDevice()
        setUpInputOutput()
        setUpPreviewLayer()
        startRunningCaptureSession()
    }
    
    func setUpCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    func setUpDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:[AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified
        )
        
        let devices = deviceDiscoverySession.devices
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        currentCamera = backCamera
    }
    
    
    
    func setUpInputOutput(){
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureDeviceInput)
            
            photoOutput = AVCapturePhotoOutput()
            
            
            photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format:[AVVideoCodecKey:AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput!)
            
            
        } catch  {
            print(error)
        }
    }
    
    func setUpPreviewLayer(){
        cameraPreviewlayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewlayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewlayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraPreviewlayer?.frame = self.view.frame
        self.view.layer.insertSublayer(cameraPreviewlayer!, at: 0)
    }
    
    func startRunningCaptureSession(){
        captureSession.startRunning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "takePhotoResult" {
            let preVC = segue.destination as! PreviewCameraViewController
            preVC.image = self.image!
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            image = UIImage(data: imageData)
            performSegue(withIdentifier: "takePhotoResult", sender: nil)
        }
    }
    
    
    @IBAction func camera(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
