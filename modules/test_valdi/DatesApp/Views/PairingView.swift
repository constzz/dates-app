import SwiftUI

struct PairingView: View {
    @ObservedObject var storage: DateStorageService
    @State private var coupleStatus: CoupleStatus?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingInviteCode = false
    @State private var inviteCode: String = ""
    @State private var showingEnterCode = false
    @State private var enteredCode: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DatesDesign.Spacing.xl) {
                    Spacer()
                        .frame(height: DatesDesign.Spacing.xxl)
                    
                    if isLoading {
                        VStack(spacing: DatesDesign.Spacing.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: DatesDesign.Colors.accent))
                                .scaleEffect(1.5)
                            
                            DatesDesign.Typography.bodySecondary("Loading...")
                        }
                        .padding()
                    } else if let status = coupleStatus {
                        if status.isPaired {
                            pairedSection(status)
                        } else {
                            unpairedSection(status)
                        }
                    } else {
                        notSetupSection
                    }
                    
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
                    }
                    
                    Spacer()
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadCoupleStatus()
            }
            .sheet(isPresented: $showingInviteCode) {
                inviteCodeSheet
            }
            .sheet(isPresented: $showingEnterCode) {
                enterCodeSheet
            }
        }
    }
    
    private func pairedSection(_ status: CoupleStatus) -> some View {
        VStack(spacing: DatesDesign.Spacing.xl) {
            // Simple icon - no gradient
            Image(systemName: "heart")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(DatesDesign.Colors.accent)
            
            VStack(spacing: DatesDesign.Spacing.sm) {
                DatesDesign.Typography.hero("You're paired!")
                    .multilineTextAlignment(.center)
                
                DatesDesign.Typography.bodySecondary(
                    "You and your partner now share the same date plans"
                )
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, DatesDesign.Spacing.lg)
            
            VStack(alignment: .leading, spacing: DatesDesign.Spacing.md) {
                HStack(spacing: DatesDesign.Spacing.sm) {
                    Image(systemName: "link")
                        .foregroundColor(DatesDesign.Colors.accent)
                    Text("Couple ID: \(status.coupleID ?? "N/A")")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(DatesDesign.Colors.textSecondary)
                }
                
                if let createdAt = status.createdAt {
                    HStack(spacing: DatesDesign.Spacing.sm) {
                        Image(systemName: "calendar")
                            .foregroundColor(DatesDesign.Colors.accent)
                        Text("Paired since: \(createdAt.prefix(10))")
                            .font(.system(size: 14, weight: .medium, ))
                            .foregroundColor(DatesDesign.Colors.textSecondary)
                    }
                }
            }
            .padding(DatesDesign.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .datesCard(elevation: .base)
            .padding(.horizontal, DatesDesign.Spacing.lg)
        }
    }
    
    private func unpairedSection(_ status: CoupleStatus) -> some View {
        VStack(spacing: DatesDesign.Spacing.xl) {
            ZStack {
                // Simple icon
                Image(systemName: "person.2")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundColor(DatesDesign.Colors.accent)
            }
            
            VStack(spacing: DatesDesign.Spacing.sm) {
                DatesDesign.Typography.hero("Invitation created")
                    .multilineTextAlignment(.center)
                
                DatesDesign.Typography.bodySecondary(
                    "Share the code below with your partner so they can join"
                )
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, DatesDesign.Spacing.lg)
            
            if !inviteCode.isEmpty {
                VStack(spacing: DatesDesign.Spacing.md) {
                    Text(inviteCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(DatesDesign.Colors.accent)
                        .padding(DatesDesign.Spacing.xl)
                        .frame(maxWidth: .infinity)
                        .datesCard(elevation: .elevated)
                    
                    Button(action: {
                        UIPasteboard.general.string = inviteCode
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Code")
                        }
                    }
                    .buttonStyle(DatesDesign.SecondaryButton())
                }
                .padding(.horizontal, DatesDesign.Spacing.lg)
            }
        }
    }
    
    private var notSetupSection: some View {
        VStack(spacing: DatesDesign.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DatesDesign.Colors.accentSoft, DatesDesign.Colors.accent.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.2.badge.gearshape")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DatesDesign.Colors.accent, DatesDesign.Colors.accentDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: DatesDesign.Spacing.sm) {
                DatesDesign.Typography.hero("Connect with\nyour partner")
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                DatesDesign.Typography.bodySecondary(
                    "Share your date plans with your partner. Both of you will see and edit the same dates."
                )
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, DatesDesign.Spacing.lg)
            
            VStack(spacing: DatesDesign.Spacing.md) {
                Button(action: {
                    Task {
                        await createInvite()
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Invitation")
                    }
                }
                .buttonStyle(DatesDesign.PrimaryButton())
                
                Button(action: {
                    showingEnterCode = true
                }) {
                    HStack {
                        Image(systemName: "keyboard")
                        Text("Enter Partner's Code")
                    }
                }
                .buttonStyle(DatesDesign.SecondaryButton())
            }
            .padding(.horizontal, DatesDesign.Spacing.lg)
        }
    }
    
    private var inviteCodeSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Invitation Code")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(inviteCode)
                    .font(.system(.largeTitle, design: .monospaced))
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                Text("Share this code with your partner")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    UIPasteboard.general.string = inviteCode
                }) {
                    Label("Copy Code", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("Done") {
                    showingInviteCode = false
                    Task {
                        await loadCoupleStatus()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var enterCodeSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter Partner's Code")
                    .font(.title)
                    .fontWeight(.bold)
                
                TextField("Invite Code", text: $enteredCode)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.title3, design: .monospaced))
                    .textCase(.uppercase)
                    .autocorrectionDisabled()
                
                Button(action: {
                    Task {
                        await acceptInvite()
                    }
                }) {
                    Label("Join Couple", systemImage: "link")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(enteredCode.isEmpty)
                
                Spacer()
                
                Button("Cancel") {
                    showingEnterCode = false
                    enteredCode = ""
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func loadCoupleStatus() async {
        isLoading = true
        errorMessage = nil
        
        do {
            coupleStatus = try await APIClient.shared.getCoupleStatus()
        } catch APIError.serverError(let message) where message.contains("paired") == false {
            // Not yet set up - this is fine
            coupleStatus = nil
        } catch {
            errorMessage = "Failed to load pairing status: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func createInvite() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let invitation = try await APIClient.shared.createInvitation()
            inviteCode = invitation.code
            showingInviteCode = true
            await loadCoupleStatus()
        } catch {
            errorMessage = "Failed to create invitation: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func acceptInvite() async {
        isLoading = true
        errorMessage = nil
        
        do {
            coupleStatus = try await APIClient.shared.acceptInvitation(code: enteredCode)
            showingEnterCode = false
            enteredCode = ""
            
            // Refresh storage to sync couple's dates
            await storage.refreshFromBackend()
        } catch {
            errorMessage = "Failed to accept invitation: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
