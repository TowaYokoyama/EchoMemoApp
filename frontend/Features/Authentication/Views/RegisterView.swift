
import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    
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
                    TextField("名前（任意）", text: $name)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .textContentType(.name)
                    
                    TextField("メールアドレス", text: $email)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("パスワード", text: $password)
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
                        await authViewModel.register(email: email, password: password, name: name)
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
                
                // 区切り線
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.theme.secondary.opacity(0.3))
                    Text("または")
                        .font(.caption)
                        .foregroundColor(.theme.secondaryText)
                        .padding(.horizontal, 8)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.theme.secondary.opacity(0.3))
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // ソーシャルログインボタン
                VStack(spacing: 12) {
                    // Apple Sign In
                    Button(action: {
                        Task {
                            await authViewModel.loginWithApple()
                            if authViewModel.isAuthenticated {
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                                .font(.title3)
                            Text("Appleで登録")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.UI.cornerRadius)
                    }
                    .disabled(authViewModel.isLoading)
                    
                    // Google Sign In
                    Button(action: {
                        Task {
                            await authViewModel.loginWithGoogle()
                            if authViewModel.isAuthenticated {
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.title3)
                            Text("Googleで登録")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(Constants.UI.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(authViewModel.isLoading)
                }
                .padding(.horizontal)
                
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
