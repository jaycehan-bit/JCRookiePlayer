//
//  JCPlayerVideoRecord.swift
//  JCRookiePlayer
//
//  Created by jaycehan on 2024/8/15.
//

import AVFoundation
import Dispatch
import Foundation

public protocol JCPlayerVideoRecordDelegate : NSObjectProtocol {
    func videoRecord(didOutput sampleBuffer: CMSampleBuffer)
}

class JCPlayerVideoRecord: NSObject {
    
    private var captureOutput: AVCaptureVideoDataOutput? = nil
    private var captureInput: AVCaptureDeviceInput? = nil
    let delegates = NSHashTable<AnyObject>(options: [.weakMemory])
    
    lazy private var queue = {
        return DispatchQueue(label: "com.jcrookieplayer.videorecordqueue", attributes: .concurrent)
    }()
    
    lazy private var captureSession: AVCaptureSession = {
        return AVCaptureSession()
    }()
    
    open func register(_ videoRecordDelegate: (any JCPlayerVideoRecordDelegate)?) {
        guard let _ = videoRecordDelegate else { return }
        delegates.add(videoRecordDelegate)
    }
    
    private func configCaptureSession() -> Bool {
        // 输入
        let discoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInDualCamera],
                                                                     mediaType: AVMediaType.video,
                                                                     position: AVCaptureDevice.Position.back)
        var captureDevice: AVCaptureDevice?
        for device in discoverySession.devices {
            if device.position == AVCaptureDevice.Position.back {
                captureDevice = device
            }
        }
        guard let _ = captureDevice else { return false }
        do {
            captureInput = try AVCaptureDeviceInput.init(device: captureDevice!)
        } catch {
            return false
        }
        // 输出
        captureOutput = AVCaptureVideoDataOutput.init()
        captureOutput?.setSampleBufferDelegate(self, queue: queue)
        // 配置输入输出
        if captureSession.canAddInput(captureInput!) {
            captureSession.addInput(captureInput!)
        }
        if captureSession.canAddOutput(captureOutput!) {
            captureSession.addOutput(captureOutput!)
        }
        // 设置分辨率
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .hd1280x720
        }
        captureSession.beginConfiguration()
        if let captureConnection = captureOutput?.connection(with: .video) {
            captureConnection.videoOrientation = .portrait
        }
        
        return true
    }
    
}

extension JCPlayerVideoRecord: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        for delegate in delegates.allObjects {
            if let validDelegate = delegate as? JCPlayerVideoRecordDelegate {
                validDelegate.videoRecord(didOutput: sampleBuffer)
            }
        }
    }
}

extension JCPlayerVideoRecord: JCRecord {
    func start() {
        
    }
    
    func pause() {
        
    }
    
    func stop() {
        
    }
}
