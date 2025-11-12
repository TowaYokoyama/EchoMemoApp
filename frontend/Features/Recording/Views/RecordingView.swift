
import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // 録音時間表示
                Text(viewModel.formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                // 波形アニメーション（簡易版）
                WaveformView(isRecording: viewModel.isRecording)
                    .frame(height: 100)
                    .padding(.horizontal)
                
                Spacer()
                
                // 録音ボタン
                Button {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.isRecording ? Color.red : Color.theme.accent)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(viewModel.isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.isRecording)
                
                // 保存ボタン
                if viewModel.hasRecording {
                    Button {
                        Task {
                            await viewModel.saveRecording()
                            if viewModel.isSaved {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("保存")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal)
                    .disabled(viewModel.isSaving)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("録音")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert(error: $viewModel.error)
        }
    }
}

struct WaveformView: View {
    let isRecording: Bool
    @State private var amplitudes: [CGFloat] = Array(repeating: 0.3, count: 50)
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<amplitudes.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.theme.accent)
                    .frame(width: 3, height: amplitudes[index] * 100)
            }
        }
        .onAppear {
            if isRecording {
                startAnimation()
            }
        }
        .onChange(of: isRecording) { newValue in
            if newValue {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isRecording {
                timer.invalidate()
                return
            }
            
            withAnimation(.easeInOut(duration: 0.1)) {
                amplitudes = amplitudes.map { _ in CGFloat.random(in: 0.2...1.0) }
            }
        }
    }
}

#Preview {
    RecordingView()
}
