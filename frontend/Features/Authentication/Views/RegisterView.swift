
import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Text("新規登録")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 入力フォーム
                VStack(spacing: 16) {
                    TextField("名前（任意）", text: $authViewModel.name)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .textContentType(.name)
                    
                    TextField("メールアドレス", text: $authViewModel.email)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("パスワード", text: $authViewModel.password)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .textContentType(.newPassword)
                    
                    Text("パスワードは8文字以上で入力してください")
                        .font(.caption)
                        .foregroundColor(.theme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // エラーメッセージ
                if let error = authViewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.theme.error)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // 登録ボタン
                Button(action: {
                    Task {
                        await authViewModel.register()
                        if authViewModel.isAuthenticated {
                            dismiss()
                        }
                    }
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("登録")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                .disabled(authViewModel.isLoading)
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RegisterView()
}
