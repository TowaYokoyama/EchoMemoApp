//
//  LoadingView.swift
//  EchoLogApp
//
//  Created on 2025/11/13
//

import SwiftUI

struct LoadingView: View {
    let message: String
    
    init(message: String = "読み込み中...") {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

// ViewModifier として使えるように
struct LoadingModifier: ViewModifier {
    let isLoading: Bool
    let message: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isLoading {
                LoadingView(message: message)
            }
        }
    }
}

extension View {
    func loading(isLoading: Bool, message: String = "読み込み中...") -> some View {
        modifier(LoadingModifier(isLoading: isLoading, message: message))
    }
}

#Preview {
    LoadingView(message: "保存中...")
}
