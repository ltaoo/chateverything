import Foundation
import AVFoundation
import Speech
import Photos

enum PermissionType {
    case microphone
    case speech
    case photos
    
    var description: String {
        switch self {
        case .microphone: return "麦克风"
        case .speech: return "语音识别"
        case .photos: return "相册"
        }
    }
}

enum PermissionStatus {
    case notDetermined
    case denied
    case authorized
    case restricted
    
    var description: String {
        switch self {
        case .notDetermined: return "未确定"
        case .denied: return "已拒绝"
        case .authorized: return "已授权"
        case .restricted: return "受限制"
        }
    }
}

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published private(set) var microphoneStatus: PermissionStatus = .notDetermined
    @Published private(set) var speechStatus: PermissionStatus = .notDetermined
    @Published private(set) var photosStatus: PermissionStatus = .notDetermined
    
    private init() {
        checkPermissionStatus()
    }
    
    func checkPermissionStatus() {
        // Check microphone status
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            microphoneStatus = .notDetermined
        case .denied:
            microphoneStatus = .denied
        case .granted:
            microphoneStatus = .authorized
        @unknown default:
            microphoneStatus = .notDetermined
        }
        
        // Check speech recognition status
        switch SFSpeechRecognizer.authorizationStatus() {
        case .notDetermined:
            speechStatus = .notDetermined
        case .denied:
            speechStatus = .denied
        case .restricted:
            speechStatus = .restricted
        case .authorized:
            speechStatus = .authorized
        @unknown default:
            speechStatus = .notDetermined
        }
        
        // Check photos status
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            photosStatus = .notDetermined
        case .denied:
            photosStatus = .denied
        case .restricted:
            photosStatus = .restricted
        case .authorized, .limited:
            photosStatus = .authorized
        @unknown default:
            photosStatus = .notDetermined
        }
    }
    
    func requestPermission(_ type: PermissionType, completion: @escaping (Bool) -> Void) {
        switch type {
        case .microphone:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.microphoneStatus = granted ? .authorized : .denied
                    completion(granted)
                }
            }
            
        case .speech:
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        self?.speechStatus = .authorized
                        completion(true)
                    case .denied:
                        self?.speechStatus = .denied
                        completion(false)
                    case .restricted:
                        self?.speechStatus = .restricted
                        completion(false)
                    case .notDetermined:
                        self?.speechStatus = .notDetermined
                        completion(false)
                    @unknown default:
                        self?.speechStatus = .notDetermined
                        completion(false)
                    }
                }
            }
            
        case .photos:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized, .limited:
                        self?.photosStatus = .authorized
                        completion(true)
                    case .denied:
                        self?.photosStatus = .denied
                        completion(false)
                    case .restricted:
                        self?.photosStatus = .restricted
                        completion(false)
                    case .notDetermined:
                        self?.photosStatus = .notDetermined
                        completion(false)
                    @unknown default:
                        self?.photosStatus = .notDetermined
                        completion(false)
                    }
                }
            }
        }
    }
} 