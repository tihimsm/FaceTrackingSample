//
//  FaceTracker.swift
//  FaceTrackingSample
//
//  Created by Taihei Mishima on 2020/10/13.
//  Copyright © 2020 Taihei Mishima. All rights reserved.
//

import UIKit
import AVFoundation

class FaceTracker: NSObject {
    let captureSession = AVCaptureSession()
    let videoDevice = AVCaptureDevice.default(for: .video)
    let audioDevice = AVCaptureDevice.default(for: .audio)
    
    var videoOutput = AVCaptureVideoDataOutput()
    var view: UIView
    private var findFace: (_ array: [CGRect]) -> Void
    required init(view: UIView, findFace: @escaping (_ array: [CGRect]) -> Void) {
        self.view = view
        self.findFace = findFace
        super.init()
        self.initialize()
    }
}

private extension FaceTracker {
    func initialize() {
        do {
            let videoInput = try AVCaptureDeviceInput(device: self.videoDevice!)
            self.captureSession.addInput(videoInput)
        } catch let error as NSError {
            print(error)
        }
        
        do {
            let audioInput = try AVCaptureDeviceInput(device: self.audioDevice!)
            self.captureSession.addInput(audioInput)
        } catch let error as NSError {
            print(error)
        }
        
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: Int(kCVPixelFormatType_32BGRA)]
        
        let queue: DispatchQueue = DispatchQueue(label: "myqueue", attributes: .concurrent)
        self.videoOutput.setSampleBufferDelegate(self, queue: queue)
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        
        self.captureSession.addOutput(self.videoOutput)
        
        let videoLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        self.view.layer.addSublayer(videoLayer)
        
        for connection in self.videoOutput.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        
        self.captureSession.startRunning()
    }
    
    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo)
        let imageRef = context!.makeImage()
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let resultImage = UIImage(cgImage: imageRef!)
        return resultImage
    }
}

extension FaceTracker: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.sync(execute: {
            let image = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            let ciImage = CIImage(image: image)!
            
            let detector: CIDetector = CIDetector(
                ofType: CIDetectorTypeFace,
                context: nil,
                options: [CIDetectorAccuracy: CIDetectorAccuracyLow])!
            
            let faces = detector.features(in: ciImage) as NSArray
            
            guard faces.count != 0 else {
                return
            }
            
            var rects: [CGRect] = []
            var _ = CIFaceFeature()
            
            for feature in faces {
                var faceRect: CGRect = (feature as AnyObject).bounds
                let widthPer: CGFloat = self.view.bounds.width / image.size.width
                let heightPer: CGFloat = self.view.bounds.height / image.size.height
                
                faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height
                faceRect.origin.x = faceRect.origin.x * widthPer
                faceRect.origin.y = faceRect.origin.y * heightPer
                faceRect.size.width = faceRect.size.width * widthPer
                faceRect.size.height = faceRect.size.height * heightPer
                
                rects.append(faceRect)
            }
            self.findFace(rects)
        })
    }
}
