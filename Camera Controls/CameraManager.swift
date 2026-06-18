import AVFoundation

final class CameraManager: ObservableObject {
    
    let session = AVCaptureSession()
    
    func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupSession()
                    }
                }
            }
            
        default:
            print("Camera permission denied")
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            print("Failed to setup camera input")
            return
        }
        
        session.addInput(input)
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
}
