//
//  ScreenRecorder.swift
//  Lunr
//
//  Created by Lwin Oo on 5/20/25.
//

import AVFoundation
import Foundation
import Vision

class ScreenRecorder: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "LunrScreenFeed")
    private let textRequest = VNRecognizeTextRequest()
    
    @Published var detectedText: String = ""
    @Published var isRunning = false

    override init() {
        super.init()
        textRequest.recognitionLevel = .fast
        textRequest.usesLanguageCorrection = false
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        guard let screenInput = AVCaptureScreenInput(displayID: CGMainDisplayID()) else {
            print("❌ Unable to access screen input")
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .high
        if session.canAddInput(screenInput) {
            session.addInput(screenInput)
        }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
        session.startRunning()
    }

    func stop() {
        session.stopRunning()
        isRunning = false
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try requestHandler.perform([textRequest])
            if let results = textRequest.results as? [VNRecognizedTextObservation] {
                let recognized = results
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")

                DispatchQueue.main.async {
                    self.detectedText = recognized
                }
            }
        } catch {
            print("❌ OCR failed: \(error)")
        }
    }
}
