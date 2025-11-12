

import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .background(Color.theme.background)
            .cornerRadius(Constants.UI.cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

extension View {
    func alert(error: Binding<Error?>) -> some View {
        alert(
            "エラー",
            isPresented: .constant(error.wrappedValue != nil),
            presenting: error.wrappedValue
        ) { _ in
            Button("OK") {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}
