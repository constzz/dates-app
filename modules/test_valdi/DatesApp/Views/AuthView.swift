import SwiftUI

struct AuthView: View {
    @ObservedObject var storage: DateStorageService
    @State private var email = ""
    @State private var password = ""
    @State private var isLogin = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DatesDesign.Spacing.xl) {
                    Spacer()
                        .frame(height: DatesDesign.Spacing.xxl)
                    
                    // Hero Icon
                    Image(systemName: "heart")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundColor(DatesDesign.Colors.accent)
                    
                    // Title & Subtitle
                    VStack(spacing: DatesDesign.Spacing.sm) {
                        DatesDesign.Typography.hero(isLogin ? "Welcome back" : "Let's start")
                            .multilineTextAlignment(.center)
                        
                        DatesDesign.Typography.bodySecondary(
                            isLogin ? 
                            "Sign in to sync your dates across devices" :
                            "Create an account to share dates with your partner"
                        )
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, DatesDesign.Spacing.lg)
                    
                    // Form
                    VStack(spacing: DatesDesign.Spacing.md) {
                        VStack(alignment: .leading, spacing: DatesDesign.Spacing.xs) {
                            
                            TextField("your@email.com", text: $email)
                                .textFieldStyle(DatesTextFieldStyle())
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }
                        
                        VStack(alignment: .leading, spacing: DatesDesign.Spacing.xs) {
                            
                            SecureField("Minimum 8 characters", text: $password)
                                .textFieldStyle(DatesTextFieldStyle())
                                .textContentType(isLogin ? .password : .newPassword)
                            
                            if !isLogin && !password.isEmpty && password.count < 8 {
                                Text("Password must be at least 8 characters")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(DatesDesign.Colors.accentDeep)
                                    .padding(.leading, DatesDesign.Spacing.xs)
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await authenticate()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isLogin ? "Sign In" : "Create Account")
                                    Image(systemName: "arrow.right")
                                }
                            }
                        }
                        .buttonStyle(DatesDesign.PrimaryButton(
                            isLoading: isLoading,
                            isDisabled: email.isEmpty || password.count < 8 || isLoading
                        ))
                        .disabled(email.isEmpty || password.count < 8 || isLoading)
                        .padding(.top, DatesDesign.Spacing.sm)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isLogin.toggle()
                                errorMessage = nil
                            }
                        }) {
                            Text(isLogin ? 
                                 "Don't have an account? **Sign up**" : 
                                 "Already have an account? **Sign in**")
                                .font(.system(size: 15, weight: .regular, ))
                                .foregroundColor(DatesDesign.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, DatesDesign.Spacing.xs)
                    }
                    .padding(.horizontal, DatesDesign.Spacing.lg)
                    
                    // Error Message
                    if let error = errorMessage {
                        HStack(spacing: DatesDesign.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                            
                            Text(error)
                                .font(.system(size: 14, weight: .medium, ))
                        }
                        .foregroundColor(DatesDesign.Colors.accentDeep)
                        .padding(DatesDesign.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DatesDesign.Colors.accentSoft)
                        .cornerRadius(DatesDesign.Radius.md)
                        .padding(.horizontal, DatesDesign.Spacing.lg)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(DatesDesign.Colors.textSecondary)
                    }
                }
            }
        }
    }
    
    private func authenticate() async {
        print("🔐 Starting authentication - isLogin: \(isLogin), email: \(email)")
        isLoading = true
        errorMessage = nil
        
        do {
            if isLogin {
                print("🔐 Attempting login...")
                _ = try await APIClient.shared.login(email: email, password: password)
            } else {
                print("🔐 Attempting registration...")
                _ = try await APIClient.shared.register(email: email, password: password)
            }
            
            print("🔐 Authentication successful, triggering onLogin...")
            // Trigger storage refresh after login
            await storage.onLogin()
            
            print("🔐 Dismissing modal...")
            dismiss()
        } catch APIError.serverError(let message) {
            print("🔐 Server error: \(message)")
            errorMessage = message
        } catch {
            print("🔐 Error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        print("🔐 Authentication flow completed, isLoading = false")
    }
}
