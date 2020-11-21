//
//  ViewController.swift
//  Greeting
//
//  Created by Grayson Halliday on 2020-05-17.
//  Copyright © 2020 Grayson Halliday. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire

class ViewController: UIViewController {
    var running: Bool = false
    var captureSession: AVCaptureSession = AVCaptureSession()
    var photoOutput = AVCapturePhotoOutput()
    var captureProcessor: PhotoCaptureProcessor? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        captureSession.beginConfiguration()
        guard let cameraDevice = AVCaptureDevice.default(for: .video) else { return }
        do {
            // Wrap the audio device in a capture device input.
            let audioInput = try AVCaptureDeviceInput(device: cameraDevice)
            // If the input can be added, add it to the session.
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
            print("not error")
        } catch {
            print("error")
            // Configuration failed. Handle error.
        }
        
        guard self.captureSession.canAddOutput(photoOutput) else { return }
        self.captureSession.sessionPreset = .photo

        self.captureSession.addOutput(photoOutput)
        self.captureSession.commitConfiguration()
        captureProcessor = PhotoCaptureProcessor(parent: self)
    }

    @IBOutlet weak var startButton: UIButton!
    @IBAction func startButton(_ sender: Any) {
        if (!running){
            self.startedLabel.text = "State: Started"
            self.running = true
            self.startButton.setTitle("Press to Stop", for: .normal)
            self.captureSession.startRunning()
            self.run()
        } else {
            self.captureSession.stopRunning()
            self.startedLabel.text = "State: Stopped"
            self.running = false
            self.startButton.setTitle("Press to Start", for: .normal)
        }
        
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    func updateAndSendImage(image: UIImage) {
        print("inside")
        self.imageView.image = image
        
        let jpegData = image.jpegData(compressionQuality: 1.0)
        
        let headers: HTTPHeaders = [
            "Content-Length": String(jpegData!.count)
        ]
        
        struct HTTPBinResponse: Decodable { let url: String }
        
        AF.upload(jpegData!, to: "http://192.168.0.50:8080", method: .post, headers: headers).responseDecodable(of: HTTPBinResponse.self) { response in
            debugPrint(response)
        }
    }
    
    @IBOutlet weak var startedLabel: UILabel!
    
    @objc func run(){
        if (self.running)
        {
            print("run")
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = .auto
            self.photoOutput.capturePhoto(with: photoSettings, delegate: captureProcessor!)
            
            _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(run), userInfo: nil, repeats: false)
        }
    }
}

class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    let parent: ViewController
    
    init(parent: ViewController) {
       self.parent = parent
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?){
        print("inside")
        guard let imageData = photo.fileDataRepresentation() else {
            print("Error while generating image from photo capture data.");
            return
        }

        guard let uiImage = UIImage(data: imageData) else { return }
        parent.updateAndSendImage(image: uiImage)
    }
}

