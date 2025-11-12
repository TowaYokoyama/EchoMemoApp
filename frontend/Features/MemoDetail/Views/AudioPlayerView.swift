
import SwiftUI

struct AudioPlayerView: View {
    let audioURL: URL
    @StateObject private var audioService = AudioService.shared
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 再生時間スライダー
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { audioService.currentTime },
                        set: { audioService.seek(to: $0) }
                    ),
                    in: 0...max(audioService.duration, 1)
                )
                .disabled(!isPlaying && audioService.currentTime == 0)
                
                HStack {
                    Text(formatTime(audioService.currentTime))
                        .font(.caption)
                        .foregroundColor(.theme.secondaryText)
                    
                    Spacer()
                    
                    Text(formatTime(audioService.duration))
                        .font(.caption)
                        .foregroundColor(.theme.secondaryText)
                }
            }
            
            // 再生ボタン
            HStack(spacing: 32) {
                Button {
                    audioService.seek(to: max(0, audioService.currentTime - 15))
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                }
                .disabled(!isPlaying && audioService.currentTime == 0)
                
                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.theme.accent)
                }
                
                Button {
                    audioService.seek(to: min(audioService.duration, audioService.currentTime + 15))
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                }
                .disabled(!isPlaying && audioService.currentTime == 0)
            }
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(Constants.UI.cornerRadius)
        .onAppear {
            isPlaying = audioService.isPlaying
        }
        .onChange(of: audioService.isPlaying) { newValue in
            isPlaying = newValue
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioService.pauseAudio()
        } else {
            do {
                try audioService.playAudio(url: audioURL)
            } catch {
                print("Failed to play audio: \(error)")
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
