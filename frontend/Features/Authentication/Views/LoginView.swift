import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingRegister = false
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // ロゴ
                Image(systemName: "waveform.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.theme.primary)
                
                Text("EchoLog")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 入力フォーム
                VStack(spacing: 16) {
                    TextField("メールアドレス", text: $email)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("パスワード", text: $password)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .textContentType(.password)
                }
                .padding(.horizontal)
                
                // エラーメッセージ
                if let error = authViewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.theme.error)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // ログインボタン
                Button(action: {
                    Task {
                        await authViewModel.login(email: email, password: password)
                    }
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("ログイン")
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
                        }
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                                .font(.title3)
                            Text("Appleでログイン")
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
                        }
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.title3)
                            Text("Googleでログイン")
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
                
                // 新規登録リンク
                Button(action: {
                    showingRegister = true
                }) {
                    Text("アカウントをお持ちでない方はこちら")
                        .font(.caption)
                        .foregroundColor(.theme.primary)
                }
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showingRegister) {
                RegisterView()
            }
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) var colorScheme
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.theme.secondaryBackground)
            .cornerRadius(Constants.UI.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .stroke(colorScheme == .light ? Color.theme.secondary.opacity(0.4) : Color.clear, lineWidth: colorScheme == .light ? 1 : 0)
            )
            .shadow(color: colorScheme == .light ? Color.theme.secondary.opacity(0.15) : Color.clear, radius: colorScheme == .light ? 3 : 0, x: 0, y: 2)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(configuration.isPressed ? Color.theme.primary.opacity(0.8) : Color.theme.primary)
            .foregroundColor(.white)
            .cornerRadius(Constants.UI.cornerRadius)
    }
}

#Preview {
    LoginView()
}
