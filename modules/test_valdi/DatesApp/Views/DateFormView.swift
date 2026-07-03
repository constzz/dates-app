import SwiftUI

struct DateFormView: View {
    @ObservedObject var storage: DateStorageService
    let editingPlan: DatePlan?
    let onDismiss: () -> Void
    
    @State private var title: String
    @State private var place: String
    @State private var selectedDate: Date?
    @State private var time: String
    @State private var vibe: DateVibe
    @State private var status: DateStatus
    @State private var notes: String
    
    init(storage: DateStorageService, editingPlan: DatePlan?, onDismiss: @escaping () -> Void) {
        self.storage = storage
        self.editingPlan = editingPlan
        self.onDismiss = onDismiss
        
        _title = State(initialValue: editingPlan?.title ?? "")
        _place = State(initialValue: editingPlan?.place ?? "")
        _selectedDate = State(initialValue: editingPlan?.date)
        _time = State(initialValue: editingPlan?.time ?? "")
        _vibe = State(initialValue: editingPlan?.vibe ?? .easy)
        _status = State(initialValue: editingPlan?.status ?? .idea)
        _notes = State(initialValue: editingPlan?.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DatesDesign.Spacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: DatesDesign.Spacing.sm) {
                        
                        DatesDesign.Typography.heading1(editingPlan != nil ? "Update details" : "What's the plan?")
                            .lineLimit(2)
                        
                        DatesDesign.Typography.bodySecondary("Fill in what you know now. You can always update it later")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, DatesDesign.Spacing.lg)
                    .padding(.top, DatesDesign.Spacing.lg)
                    
                    // Form Fields
                    VStack(spacing: DatesDesign.Spacing.lg) {
                        // Title
                        VStack(alignment: .leading, spacing: DatesDesign.Spacing.xs) {
                            
                            TextField("Dinner at...", text: $title)
                                .textFieldStyle(DatesTextFieldStyle())
                        }
                        
                        // Place
                        VStack(alignment: .leading, spacing: DatesDesign.Spacing.xs) {
                            
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(DatesDesign.Colors.textSecondary)
                                TextField("Restaurant name or area", text: $place)
                            }
                            .textFieldStyle(DatesTextFieldStyle())
                        }
                        
                        // Date & Time
                        VStack(alignment: .leading, spacing: DatesDesign.Spacing.md) {
                            HStack {
                                
                                Spacer()
                                
                                Toggle("Specific date", isOn: Binding(
                                    get: { selectedDate != nil },
                                    set: { if !$0 { selectedDate = nil } else { selectedDate = Date() } }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: DatesDesign.Colors.accent))
                                .labelsHidden()
                            }
                            
                            if selectedDate != nil {
                                VStack(spacing: DatesDesign.Spacing.sm) {
                                    DatePicker(
                                        "Date",
                                        selection: Binding(
                                            get: { selectedDate ?? Date() },
                                            set: { selectedDate = $0 }
                                        ),
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(DatesDesign.Spacing.md)
                                    .background(DatesDesign.Colors.surfaceElevated)
                                    .cornerRadius(DatesDesign.Radius.md)
                                    
                                    TextField("Time (optional)", text: $time)
                                        .textFieldStyle(DatesTextFieldStyle())
                                }
                            }
                        }
                        
                        // Vibe Selection
                        VStack(alignment: .leading, spacing: DatesDesign.Spacing.md) {
                            
                            VStack(spacing: DatesDesign.Spacing.sm) {
                                ForEach(DateVibe.allCases, id: \.self) { v in
                                    DatesDesign.VibeTag(vibe: v, isSelected: vibe == v) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            vibe = v
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Status
                        VStack(alignment: .leading, spacing: DatesDesign.Spacing.md) {
                            
                            HStack(spacing: DatesDesign.Spacing.sm) {
                                ForEach(DateStatus.allCases, id: \.self) { s in
                                    statusButton(s)
                                }
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: DatesDesign.Spacing.xs) {
                            
                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("Add any extra details, reminders, or ideas...")
                                        .font(.system(size: 16, weight: .regular, ))
                                        .foregroundColor(DatesDesign.Colors.textTertiary)
                                        .padding(DatesDesign.Spacing.md)
                                }
                                
                                TextEditor(text: $notes)
                                    .font(.system(size: 16, weight: .regular, ))
                                    .foregroundColor(DatesDesign.Colors.textPrimary)
                                    .frame(minHeight: 100)
                                    .padding(DatesDesign.Spacing.sm)
                                    .background(DatesDesign.Colors.surfaceElevated)
                                    .cornerRadius(DatesDesign.Radius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DatesDesign.Radius.md)
                                            .strokeBorder(DatesDesign.Colors.border, lineWidth: 1.5)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, DatesDesign.Spacing.lg)
                    
                    // Action Buttons
                    VStack(spacing: DatesDesign.Spacing.md) {
                        Button("Save Date") {
                            savePlan()
                        }
                        .buttonStyle(DatesDesign.PrimaryButton())
                        .disabled(title.isEmpty || place.isEmpty)
                        
                        Button("Cancel") {
                            onDismiss()
                        }
                        .buttonStyle(DatesDesign.SecondaryButton())
                        
                        if editingPlan != nil {
                            Button("Delete Date") {
                                if let id = editingPlan?.id {
                                    storage.deletePlan(id)
                                    onDismiss()
                                }
                            }
                            .font(.system(size: 15, weight: .medium, ))
                            .foregroundColor(DatesDesign.Colors.accentDeep)
                            .padding(.top, DatesDesign.Spacing.sm)
                        }
                    }
                    .padding(.horizontal, DatesDesign.Spacing.lg)
                    .padding(.bottom, DatesDesign.Spacing.xl)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(DatesDesign.Colors.textSecondary)
                    }
                }
            }
        }
    }
    
    private func statusButton(_ s: DateStatus) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                status = s
            }
        } label: {
            VStack(spacing: DatesDesign.Spacing.xs) {
                Image(systemName: statusIcon(s))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(status == s ? .white : DatesDesign.Colors.textPrimary)
                
                Text(statusLabel(s))
                    .font(.system(size: 13, weight: .semibold, ))
                    .foregroundColor(status == s ? .white : DatesDesign.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DatesDesign.Spacing.md)
            .background(status == s ? DatesDesign.Colors.accent : DatesDesign.Colors.surface)
            .cornerRadius(DatesDesign.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DatesDesign.Radius.md)
                    .strokeBorder(status == s ? Color.clear : DatesDesign.Colors.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusIcon(_ s: DateStatus) -> String {
        switch s {
        case .idea: return "lightbulb.fill"
        case .planned: return "calendar"
        case .completed: return "checkmark.circle.fill"
        case .archived: return "archivebox.fill"
        }
    }
    
    private func statusLabel(_ s: DateStatus) -> String {
        switch s {
        case .idea: return "Idea"
        case .planned: return "Planned"
        case .completed: return "Done"
        case .archived: return "Archived"
        }
    }
    
    private func savePlan() {
        let plan = DatePlan(
            id: editingPlan?.id ?? UUID().uuidString,
            title: title,
            place: place,
            date: selectedDate,
            time: time.isEmpty ? nil : time,
            vibe: vibe,
            status: status,
            notes: notes,
            createdAt: editingPlan?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        storage.savePlan(plan)
        onDismiss()
    }
}
