import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingRegister = false
    
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
                    TextField("メールアドレス", text: $authViewModel.email)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("パスワード", text: $authViewModel.password)
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
                        await authViewModel.login()
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
