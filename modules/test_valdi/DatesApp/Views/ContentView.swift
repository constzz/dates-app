import SwiftUI

struct ContentView: View {
    @StateObject private var storage = DateStorageService()
    @State private var showingForm = false
    @State private var showingPairing = false
    @State private var showingAuth = false
    @State private var editingPlan: DatePlan?
    @State private var selectedStatusFilter: DateStatus?
    @State private var selectedVibeFilter: DateVibe?
    @State private var isRefreshing = false
    
    var filteredPlans: [DatePlan] {
        storage.plans.filter { plan in
            let statusMatch = selectedStatusFilter == nil || plan.status == selectedStatusFilter
            let vibeMatch = selectedVibeFilter == nil || plan.vibe == selectedVibeFilter
            return statusMatch && vibeMatch
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DatesDesign.Spacing.lg) {
                    headerSection
                    heroSection
                    quickStatsSection
                    activeFiltersSection
                    allPlansSection
                }
                .padding(DatesDesign.Spacing.md)
                .padding(.top, DatesDesign.Spacing.xs)
            }
            .background(Color(.systemBackground))
            .refreshable {
                await refreshData()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { 
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showingAuth = true 
                    }) {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: APIConfig.accessToken == nil ? "person" : "person.fill")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(DatesDesign.Colors.textPrimary)
                            
                            if storage.isOnline {
                                Circle()
                                    .fill(DatesDesign.Colors.statusCompleted)
                                    .frame(width: 10, height: 10)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(.systemBackground), lineWidth: 2)
                                    )
                                    .offset(x: 2, y: 2)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showingPairing = true 
                    }) {
                        Image(systemName: storage.isPaired ? "heart.fill" : "heart")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(storage.isPaired ? DatesDesign.Colors.accent : DatesDesign.Colors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                DateFormView(storage: storage, editingPlan: editingPlan) {
                    showingForm = false
                    editingPlan = nil
                }
            }
            .sheet(isPresented: $showingPairing) {
                PairingView(storage: storage)
            }
            .sheet(isPresented: $showingAuth) {
                AuthView(storage: storage)
            }
        }
    }
    
    private func refreshData() async {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await storage.syncWithBackend()
        
        let successGenerator = UINotificationFeedbackGenerator()
        successGenerator.notificationOccurred(.success)
    }
    
    private var activeFiltersSection: some View {
        Group {
            if selectedStatusFilter != nil || selectedVibeFilter != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DatesDesign.Spacing.xs) {
                        if let status = selectedStatusFilter {
                            filterChip(
                                label: status.rawValue.capitalized,
                                systemImage: "circle.fill",
                                color: statusColor(status)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedStatusFilter = nil
                                }
                                let generator = UIImpactFeedbackGenerator(style: .soft)
                                generator.impactOccurred()
                            }
                        }
                        
                        if let vibe = selectedVibeFilter {
                            filterChip(
                                label: vibe.label,
                                systemImage: "sparkles",
                                color: vibeColor(vibe)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedVibeFilter = nil
                                }
                                let generator = UIImpactFeedbackGenerator(style: .soft)
                                generator.impactOccurred()
                            }
                        }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedStatusFilter = nil
                                selectedVibeFilter = nil
                            }
                            let generator = UIImpactFeedbackGenerator(style: .soft)
                            generator.impactOccurred()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                Text("Clear all")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(DatesDesign.Colors.textSecondary)
                            .padding(.horizontal, DatesDesign.Spacing.sm)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(DatesDesign.Radius.pill)
                        }
                    }
                    .padding(.horizontal, DatesDesign.Spacing.xs)
                }
            }
        }
    }
    
    private func filterChip(label: String, systemImage: String, color: Color, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 10))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DatesDesign.Colors.textPrimary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(DatesDesign.Colors.textSecondary)
            }
        }
        .padding(.horizontal, DatesDesign.Spacing.sm)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .cornerRadius(DatesDesign.Radius.pill)
    }
    
    private func statusColor(_ status: DateStatus) -> Color {
        switch status {
        case .idea: return DatesDesign.Colors.accent
        case .planned: return DatesDesign.Colors.statusPlanned
        case .completed: return DatesDesign.Colors.statusCompleted
        case .archived: return DatesDesign.Colors.textTertiary
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DatesDesign.Spacing.md) {
            HStack {
                DatesDesign.Typography.heading1("Dates")
                
                Spacer()
                
                if storage.isPaired {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10, weight: .regular))
                        Text("Paired")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(DatesDesign.Colors.accent)
                    .padding(.horizontal, DatesDesign.Spacing.sm)
                    .padding(.vertical, 6)
                    .background(DatesDesign.Colors.accentSoft)
                    .cornerRadius(DatesDesign.Radius.pill)
                }
            }
        }
        .padding(.bottom, DatesDesign.Spacing.md)
    }
    
    private var heroSection: some View {
        VStack(spacing: DatesDesign.Spacing.md) {
            // Next Up Card - Prominent
            VStack(alignment: .leading, spacing: DatesDesign.Spacing.md) {
                HStack {
                    DatesDesign.IconCircle(
                        systemName: "sparkles",
                        color: DatesDesign.Colors.accent,
                        size: 40
                    )
                    
                    Spacer()
                    
                    if storage.nextPlan != nil {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(DatesDesign.Colors.accent)
                    }
                }
                
                VStack(alignment: .leading, spacing: DatesDesign.Spacing.xs) {
                    if let next = storage.nextPlan {
                        DatesDesign.Typography.heading2(next.title)
                            .lineLimit(2)
                        
                        HStack(spacing: DatesDesign.Spacing.sm) {
                            Label(next.place, systemImage: "mappin.circle.fill")
                                .font(.system(size: 15, weight: .medium, ))
                                .foregroundColor(DatesDesign.Colors.textSecondary)
                            
                            if let _ = next.date {
                                Circle()
                                    .fill(DatesDesign.Colors.textTertiary)
                                    .frame(width: 3, height: 3)
                                
                                Text(next.formattedTiming)
                                    .font(.system(size: 15, weight: .medium, ))
                                    .foregroundColor(DatesDesign.Colors.textSecondary)
                            }
                        }
                        
                        DatesDesign.StatusBadge(status: next.status)
                    } else {
                        DatesDesign.Typography.heading2("No dates yet")
                            .lineLimit(2)
                        
                        DatesDesign.Typography.bodySecondary("Add your first date idea to get started")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(DatesDesign.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .datesCard(elevation: .prominent)
            .overlay(
                RoundedRectangle(cornerRadius: DatesDesign.Radius.lg)
                    .strokeBorder(
                        storage.nextPlan != nil ? DatesDesign.Colors.accent.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
            .onTapGesture {
                if let next = storage.nextPlan {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    editingPlan = next
                    showingForm = true
                }
            }
            
            // Quick Action Button
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                editingPlan = nil
                showingForm = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add new date idea")
                            .font(.system(size: 16, weight: .semibold, ))
                        Text("Capture a place, time, and vibe")
                            .font(.system(size: 13, weight: .regular, ))
                            .opacity(0.8)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(DatesDesign.Spacing.lg)
                .background(
                    LinearGradient(
                        colors: [DatesDesign.Colors.accent, DatesDesign.Colors.accentDeep],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(DatesDesign.Radius.lg)
                .shadow(color: DatesDesign.Colors.accent.opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: DatesDesign.Spacing.sm) {
            statCard(
                value: "\(storage.ideasCount)",
                label: "Ideas",
                icon: "lightbulb.fill",
                color: DatesDesign.Colors.accent
            )
            
            statCard(
                value: "\(storage.plans.filter { $0.status == .planned }.count)",
                label: "Planned",
                icon: "calendar",
                color: DatesDesign.Colors.statusPlanned
            )
            
            statCard(
                value: "\(storage.plans.filter { $0.status == .completed }.count)",
                label: "Done",
                icon: "checkmark.circle.fill",
                color: DatesDesign.Colors.statusCompleted
            )
        }
    }
    
    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: DatesDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, ))
                .foregroundColor(DatesDesign.Colors.textPrimary)
            
            Text(label)
                .font(.system(size: 12, weight: .medium, ))
                .foregroundColor(DatesDesign.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DatesDesign.Spacing.lg)
        .datesCard(elevation: .base)
    }
    
    private var allPlansSection: some View {
        VStack(alignment: .leading, spacing: DatesDesign.Spacing.md) {
            HStack {
                DatesDesign.Typography.heading3("All Your Dates")
                
                Spacer()
                
                Menu {
                    Section("Status") {
                        Button(action: { selectedStatusFilter = nil }) {
                            Label("All", systemImage: selectedStatusFilter == nil ? "checkmark" : "")
                        }
                        ForEach(DateStatus.allCases, id: \.self) { status in
                            Button(action: { selectedStatusFilter = status }) {
                                Label(
                                    status.rawValue.capitalized,
                                    systemImage: selectedStatusFilter == status ? "checkmark" : ""
                                )
                            }
                        }
                    }
                    
                    Section("Vibe") {
                        Button(action: { selectedVibeFilter = nil }) {
                            Label("All", systemImage: selectedVibeFilter == nil ? "checkmark" : "")
                        }
                        ForEach(DateVibe.allCases, id: \.self) { vibe in
                            Button(action: { selectedVibeFilter = vibe }) {
                                Label(
                                    vibe.label,
                                    systemImage: selectedVibeFilter == vibe ? "checkmark" : ""
                                )
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Filter")
                            .font(.system(size: 14, weight: .medium, ))
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18))
                    }
                    .foregroundColor(DatesDesign.Colors.accent)
                    .padding(.horizontal, DatesDesign.Spacing.sm)
                    .padding(.vertical, DatesDesign.Spacing.xs)
                    .background(DatesDesign.Colors.accentSoft)
                    .cornerRadius(DatesDesign.Radius.sm)
                }
            }
            .padding(.horizontal, DatesDesign.Spacing.xs)
            
            if storage.plans.isEmpty {
                VStack(spacing: DatesDesign.Spacing.md) {
                    DatesDesign.IconCircle(
                        systemName: "calendar.badge.plus",
                        color: DatesDesign.Colors.accent,
                        size: 64
                    )
                    
                    VStack(spacing: DatesDesign.Spacing.xs) {
                        DatesDesign.Typography.heading3("No dates yet")
                        DatesDesign.Typography.bodySecondary("Tap here to add your first date idea")
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DatesDesign.Spacing.xxl)
                .contentShape(Rectangle())
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    editingPlan = nil
                    showingForm = true
                }
            } else if filteredPlans.isEmpty {
                VStack(spacing: DatesDesign.Spacing.md) {
                    DatesDesign.IconCircle(
                        systemName: "line.3.horizontal.decrease.circle",
                        color: DatesDesign.Colors.textTertiary,
                        size: 56
                    )
                    
                    VStack(spacing: DatesDesign.Spacing.xs) {
                        DatesDesign.Typography.heading3("No matches")
                        DatesDesign.Typography.bodySecondary("Try adjusting your filters")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DatesDesign.Spacing.xl)
            } else {
                VStack(spacing: DatesDesign.Spacing.sm) {
                    ForEach(filteredPlans) { plan in
                        Group {
                            if #available(iOS 16.0, *) {
                                NavigationLink(destination: DateDetailView(storage: storage, plan: plan)) {
                                    planRow(plan)
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                planRow(plan)
                                    .onTapGesture {
                                        editingPlan = plan
                                        showingForm = true
                                    }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    storage.deletePlan(plan.id)
                                }
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            if plan.status != .completed {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        var updatedPlan = plan
                                        updatedPlan.status = plan.status == .idea ? .planned : .completed
                                        storage.savePlan(updatedPlan)
                                    }
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                } label: {
                                    Label(
                                        plan.status == .idea ? "Plan" : "Complete",
                                        systemImage: plan.status == .idea ? "calendar" : "checkmark.circle.fill"
                                    )
                                }
                                .tint(plan.status == .idea ? DatesDesign.Colors.statusPlanned : DatesDesign.Colors.statusCompleted)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func planRow(_ plan: DatePlan) -> some View {
        HStack(alignment: .top, spacing: DatesDesign.Spacing.md) {
            // Vibe Icon
            ZStack {
                Circle()
                    .fill(vibeColor(plan.vibe).opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Text(vibeEmoji(plan.vibe))
                    .font(.system(size: 24))
            }
            
            // Content
            VStack(alignment: .leading, spacing: DatesDesign.Spacing.xs) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title)
                            .font(.system(size: 17, weight: .semibold, ))
                            .foregroundColor(DatesDesign.Colors.textPrimary)
                            .lineLimit(2)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                            Text(plan.place)
                                .font(.system(size: 14, weight: .medium, ))
                        }
                        .foregroundColor(DatesDesign.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    DatesDesign.StatusBadge(status: plan.status)
                }
                
                if let date = plan.date {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(date, style: .date)
                            .font(.system(size: 13, weight: .medium, ))
                        
                        if let time = plan.time {
                            Circle()
                                .fill(DatesDesign.Colors.textTertiary)
                                .frame(width: 3, height: 3)
                            Text(time)
                                .font(.system(size: 13, weight: .medium, ))
                        }
                    }
                    .foregroundColor(DatesDesign.Colors.textSecondary)
                }
                
                if !plan.notes.isEmpty {
                    Text(plan.notes)
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundColor(DatesDesign.Colors.textSecondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
        }
        .padding(DatesDesign.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .datesCard(elevation: .base)
    }
    
    private func vibeColor(_ vibe: DateVibe) -> Color {
        switch vibe {
        case .easy: return DatesDesign.Colors.accent
        case .classic: return DatesDesign.Colors.textPrimary
        case .spontaneous: return DatesDesign.Colors.accent
        case .adventure: return DatesDesign.Colors.statusPlanned
        case .relaxed: return DatesDesign.Colors.accent
        case .fancy: return DatesDesign.Colors.accent
        }
    }
    
    private func vibeEmoji(_ vibe: DateVibe) -> String {
        switch vibe {
        case .easy: return "☕️"
        case .classic: return "🎩"
        case .spontaneous: return "🎲"
        case .adventure: return "🎒"
        case .relaxed: return "🌙"
        case .fancy: return "✨"
        }
    }
}

#Preview {
    ContentView()
}
