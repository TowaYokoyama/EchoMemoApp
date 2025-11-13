
import Foundation
import AVFoundation

class AudioService: NSObject, ObservableObject {
    static let shared = AudioService()
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?
    private var timer: Timer?
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Recording
    
    func startRecording() throws {
        let recordingSession = AVAudioSession.sharedInstance()
        
        // マイクの許可確認
        recordingSession.requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    do {
                        try self?.beginRecording()
                    } catch {
                        print("Failed to start recording: \(error)")
                    }
                } else {
                    print("Recording permission denied")
                }
            }
        }
    }
    
    private func beginRecording() throws {
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent(fileName)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()
        
        isRecording = true
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        return recordingURL
    }
    
    // MARK: - Playing
    
    func playAudio(url: URL) throws {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        
        duration = audioPlayer?.duration ?? 0
        audioPlayer?.play()
        isPlaying = true
        
        startTimer()
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func resumeAudio() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCurrentTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateCurrentTime() {
        currentTime = audioPlayer?.currentTime ?? 0
    }
    
    // MARK: - Transcription
    
    func transcribeAudio(url: URL) async throws -> String {
        print("🎤 [AUDIO] Starting transcription for: \(url.lastPathComponent)")
        
        // 音声ファイルをデータに変換
        let audioData = try Data(contentsOf: url)
        print("📦 [AUDIO] Audio file size: \(audioData.count) bytes")
        
        // APIにアップロード（デフォルトのfieldName="file"を使用）
        let responseData = try await APIService.shared.upload(
            endpoint: "/transcribe",
            fileData: audioData,
            fileName: url.lastPathComponent,
            mimeType: "audio/m4a"
        )
        
        struct TranscriptionResponse: Decodable {
            let text: String
        }
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(TranscriptionResponse.self, from: responseData)
        print("✅ [AUDIO] Transcription completed: \(response.text.prefix(50))...")
        return response.text
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
}
