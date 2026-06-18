import AVFoundation
import Vision
import Combine
import CoreGraphics

class CameraCoordinator: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    var exerciseType: ExerciseType = .sideArmRaise
    var currentSide: String = "RIGHT"
    var onPoseDetected: ((ArmState) -> Void)?
    
    struct JointTriple {
        let p1: CGPoint 
        let p2: CGPoint
        let p3: CGPoint
    }

    @Published var jointTriple: JointTriple?
    
    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }
    
    func configureSession() {
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) { session.addInput(input) }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(output) { session.addOutput(output) }
        
        session.commitConfiguration()
    }
    
    func startSession() { 
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() } 
    }
    
    func stopSession() { self.session.stopRunning() }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored)
        
        try? handler.perform([request])
        guard let observation = request.results?.first else { return }
        
        self.evaluateExercise(observation)
    }
    
    private func evaluateExercise(_ observation: VNHumanBodyPoseObservation) {
        let shoulderKey: VNHumanBodyPoseObservation.JointName = (currentSide == "RIGHT") ? .rightShoulder : .leftShoulder
        let elbowKey: VNHumanBodyPoseObservation.JointName = (currentSide == "RIGHT") ? .rightElbow : .leftElbow
        let wristKey: VNHumanBodyPoseObservation.JointName = (currentSide == "RIGHT") ? .rightWrist : .leftWrist
        let hipKey: VNHumanBodyPoseObservation.JointName = (currentSide == "RIGHT") ? .rightHip : .leftHip
        let kneeKey: VNHumanBodyPoseObservation.JointName = (currentSide == "RIGHT") ? .rightKnee : .leftKnee
        let ankleKey: VNHumanBodyPoseObservation.JointName = (currentSide == "RIGHT") ? .rightAnkle : .leftAnkle

        let shoulder = try? observation.recognizedPoint(shoulderKey)
        let elbow = try? observation.recognizedPoint(elbowKey)
        let wrist = try? observation.recognizedPoint(wristKey)
        let hip = try? observation.recognizedPoint(hipKey)
        let knee = try? observation.recognizedPoint(kneeKey)
        let ankle = try? observation.recognizedPoint(ankleKey)

        let isLeg = (exerciseType == .kneeExtension || exerciseType == .hipFlexion)

        DispatchQueue.main.async {
            if isLeg, let h = hip, let k = knee, let a = ankle, h.confidence > 0.3 {
                self.jointTriple = JointTriple(
                    p1: CGPoint(x: CGFloat(h.location.x), y: CGFloat(h.location.y)),
                    p2: CGPoint(x: CGFloat(k.location.x), y: CGFloat(k.location.y)),
                    p3: CGPoint(x: CGFloat(a.location.x), y: CGFloat(a.location.y))
                )
            } else if let s = shoulder, let e = elbow, let w = wrist, s.confidence > 0.3 {
                self.jointTriple = JointTriple(
                    p1: CGPoint(x: CGFloat(s.location.x), y: CGFloat(s.location.y)),
                    p2: CGPoint(x: CGFloat(e.location.x), y: CGFloat(e.location.y)),
                    p3: CGPoint(x: CGFloat(w.location.x), y: CGFloat(w.location.y))
                )
            } else {
                self.jointTriple = nil
            }
        }

        switch exerciseType {
        case .seatedTrunkExtension:
            // Rule: shoulder.y > 0.45 => .up, shoulder.y < 0.35 => .hold, else .down
            if let s = shoulder, s.confidence > 0.5 {
                if s.location.y > 0.45 { self.onPoseDetected?(.up) }
                else if s.location.y < 0.35 { self.onPoseDetected?(.hold) }
                else { self.onPoseDetected?(.down) }
            }
        case .sideArmRaise:
            // Rule: wrist.y > shoulder.y - 0.05 => .up, else .down
            if let s = shoulder, let w = wrist, w.confidence > 0.5, s.confidence > 0.0 {
                self.onPoseDetected?(w.location.y > (s.location.y - 0.05) ? .up : .down)
            }
        case .bicepCurl:
            // Rule: wrist.y > elbow.y + 0.05 => .up, else .down
            if let e = elbow, let w = wrist, w.confidence > 0.5, e.confidence > 0.0 {
                self.onPoseDetected?(w.location.y > (e.location.y + 0.05) ? .up : .down)
            }
        case .kneeExtension:
            // Rule: ankle.y > knee.y - 0.15 => .up, else .down
            if let k = knee, let a = ankle, k.confidence > 0.3, a.confidence > 0.3 {
                self.onPoseDetected?(a.location.y > (k.location.y - 0.15) ? .up : .down)
            }
        case .hipFlexion:
            // Rule: knee.y > hip.y - 0.05 => .up, else .down
            if let h = hip, let k = knee, k.confidence > 0.3, h.confidence > 0.0 {
                self.onPoseDetected?(k.location.y > (h.location.y - 0.05) ? .up : .down)
            }
        case .trunkRotation:
            // Rule: abs(wrist.x - shoulder.x) > 0.15 => .hold, else .wrong
            if let s = shoulder, let w = wrist, w.confidence > 0.3, s.confidence > 0.0 {
                self.onPoseDetected?(abs(w.location.x - s.location.x) > 0.15 ? .hold : .wrong)
            }
        case .wristBend:
            // Rule: abs(wrist.y - elbow.y) > 0.08 => .up, else .down
            if let e = elbow, let w = wrist, w.confidence > 0.5, e.confidence > 0.0 {
                self.onPoseDetected?(abs(w.location.y - e.location.y) > 0.08 ? .up : .down)
            }
        case .wristHold:
            // Rule: abs(wrist.x - shoulder.x) < 0.25 => .hold, else .wrong
            if let s = shoulder, let w = wrist, w.confidence > 0.3, s.confidence > 0.0 {
                self.onPoseDetected?(abs(w.location.x - s.location.x) < 0.25 ? .hold : .wrong)
            }
        }
    }
}

