

import Foundation
import Combine
import UserNotifications

@MainActor
class RecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isSaving = false
    @Published var isSaved = false
    @Published var hasRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var error: Error?
    @Published var enableNotifications = false
    @Published var extractedDateTime: DateTimeInfo?
    @Published var notificationScheduled = false
    
    private var recordingURL: URL?
    private var timer: Timer?
    private let audioService = AudioService.shared
    
    // テスト用: 即座に通知を送信
    func sendTestNotification() {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "🔔 テスト通知"
        content.body = "通知機能が正常に動作しています！"
        content.sound = .default
        
        // 5秒後に通知
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Test notification failed: \(error)")
            } else {
                print("✅ Test notification scheduled for 5 seconds from now")
            }
        }
    }
    
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
            
            // 日時抽出（通知が有効な場合）
            if enableNotifications {
                print("📅 Extracting datetime from: \(transcription)")
                if let dateTimeInfo = try? await OpenAIService.shared.extractDateTime(content: transcription) {
                    extractedDateTime = dateTimeInfo
                    print("✅ DateTime extracted:")
                    print("   Date: \(dateTimeInfo.date)")
                    print("   Original text: \(dateTimeInfo.originalText)")
                    print("   Current time: \(Date())")
                    print("   Time until notification: \(dateTimeInfo.date.timeIntervalSince(Date())) seconds")
                    
                    // 未来の日時かチェック
                    if dateTimeInfo.date > Date() {
                        print("✅ Date is in the future, scheduling notification...")
                        scheduleNotification(for: dateTimeInfo, title: title, content: transcription)
                    } else {
                        print("⚠️ Extracted date is in the past, skipping notification")
                        print("   Extracted: \(dateTimeInfo.date)")
                        print("   Current: \(Date())")
                    }
                } else {
                    print("ℹ️ No datetime found in transcription")
                }
            }
            
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
    
    private func scheduleNotification(for dateTimeInfo: DateTimeInfo, title: String, content memoContent: String) {
        print("🔔 Attempting to schedule notification for \(dateTimeInfo.date)")
        print("   Original text: \(dateTimeInfo.originalText)")
        
        let center = UNUserNotificationCenter.current()
        
        // 通知権限をリクエスト
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
                
                // 通知コンテンツを作成
                let notificationContent = UNMutableNotificationContent()
                notificationContent.title = "📝 メモのリマインダー"
                notificationContent.body = "\(dateTimeInfo.originalText): \(title)"
                notificationContent.sound = .default
                
                // トリガーを作成（指定日時）
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dateTimeInfo.date)
                print("   Scheduling for:")
                print("      year=\(components.year ?? 0), month=\(components.month ?? 0), day=\(components.day ?? 0)")
                print("      hour=\(components.hour ?? 0), minute=\(components.minute ?? 0)")
                print("      timezone: \(calendar.timeZone.identifier)")
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                print("   Trigger next fire date: \(String(describing: trigger.nextTriggerDate()))")
                
                // 通知リクエストを作成
                let identifier = UUID().uuidString
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: notificationContent,
                    trigger: trigger
                )
                
                // 通知をスケジュール
                center.add(request) { [weak self] error in
                    Task { @MainActor in
                        if let error = error {
                            print("❌ Notification scheduling failed: \(error)")
                        } else {
                            print("✅ Notification scheduled successfully!")
                            print("   Notification ID: \(identifier)")
                            print("   Will fire at: \(dateTimeInfo.date)")
                            
                            self?.notificationScheduled = true
                            
                            // スケジュール済み通知を確認
                            center.getPendingNotificationRequests { requests in
                                print("📋 Total pending notifications: \(requests.count)")
                                for req in requests {
                                    print("   - \(req.identifier): \(req.content.title)")
                                }
                            }
                        }
                    }
                }
            } else {
                print("❌ Notification permission denied")
                if let error = error {
                    print("   Error: \(error)")
                }
            }
        }
    }
}
