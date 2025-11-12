

import Foundation
import Combine

@MainActor
class RecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isSaving = false
    @Published var isSaved = false
    @Published var hasRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var error: Error?
    
    private var recordingURL: URL?
    private var timer: Timer?
    private let audioService = AudioService.shared
    
    var formattedTime: String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startRecording() {
        do {
            try audioService.startRecording()
            isRecording = true
            startTimer()
        } catch {
            self.error = error
        }
    }
    
    func stopRecording() {
        recordingURL = audioService.stopRecording()
        isRecording = false
        hasRecording = recordingURL != nil
        stopTimer()
    }
    
    func saveRecording() async {
        guard let url = recordingURL else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "録音ファイルが見つかりません"])
            return
        }
        
        print("🎙️ Starting to save recording: \(url)")
        isSaving = true
        error = nil
        
        do {
            // 文字起こし
            print("📝 Transcribing audio...")
            let transcription = try await audioService.transcribeAudio(url: url)
            print("✅ Transcription: \(transcription.prefix(50))...")
            
            // タイトル生成
            print("📋 Generating title...")
            let title = try await OpenAIService.shared.generateMemoTitle(content: transcription)
            print("✅ Title: \(title)")
            
            // タグ抽出
            print("🏷️ Extracting tags...")
            let tags = try await OpenAIService.shared.extractTags(content: transcription)
            print("✅ Tags: \(tags)")
            
            // メモ保存
            print("💾 Saving memo to server...")
            _ = try await MemoService.shared.createMemo(
                title: title,
                content: transcription,
                tags: tags,
                audioURL: url.absoluteString
            )
            print("✅ Memo saved successfully!")
            
            isSaved = true
        } catch let apiError as APIError {
            print("❌ Save recording failed: \(apiError)")
            self.error = apiError
        } catch {
            print("❌ Save recording error: \(error)")
            self.error = error
        }
        
        isSaving = false
    }
    
    private func startTimer() {
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingTime += 1
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
