import SwiftUI
import PhotosUI

@available(iOS 16.0, *)
struct DateDetailView: View {
    @ObservedObject var storage: DateStorageService
    @State var plan: DatePlan
    @State private var isEditing = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DatesDesign.Spacing.lg) {
                headerSection
                timingSection
                vibeAndStatusSection
                notesSection
                photosSection
                metadataSection
            }
            .padding(DatesDesign.Spacing.lg)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isEditing = true
                } label: {
                    Text("Edit")
                        .font(.system(size: 16, weight: .semibold, ))
                        .foregroundColor(DatesDesign.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            DateFormView(storage: storage, editingPlan: plan) {
                isEditing = false
                if let updated = storage.plans.first(where: { $0.id == plan.id }) {
                    plan = updated
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DatesDesign.Spacing.md) {
            // Vibe emoji (not SF Symbol)
            ZStack {
                Circle()
                    .fill(vibeColor(plan.vibe).opacity(0.12))
                    .frame(width: 64, height: 64)
                
                Text(vibeEmoji(plan.vibe))
                    .font(.system(size: 32))
            }
            
            VStack(alignment: .leading, spacing: DatesDesign.Spacing.sm) {
                DatesDesign.Typography.hero(plan.title)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: DatesDesign.Spacing.xs) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(DatesDesign.Colors.accent)
                    
                    Text(plan.place)
                        .font(.system(size: 18, weight: .medium, ))
                        .foregroundColor(DatesDesign.Colors.textSecondary)
                }
            }
            
            DatesDesign.StatusBadge(status: plan.status)
        }
        .padding(DatesDesign.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .datesCard(elevation: .prominent)
    }
    
    private var timingSection: some View {
        VStack(alignment: .leading, spacing: DatesDesign.Spacing.md) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DatesDesign.Colors.accent)
                
                DatesDesign.Typography.heading3("When")
            }
            
            HStack(spacing: DatesDesign.Spacing.lg) {
                if let date = plan.date {
                    VStack(alignment: .leading, spacing: DatesDesign.Spacing.xs) {
                        Text(date, style: .date)
                            .font(.system(size: 17, weight: .semibold, ))
                            .foregroundColor(DatesDesign.Colors.textPrimary)
                    }
                    
                    if let time = plan.time {
                        Divider()
                            .frame(height: 40)
                        
                        VStack(alignment: .leading, spacing: DatesDesign.Spacing.xs) {
                            Text(time)
                                .font(.system(size: 17, weight: .semibold, ))
                                .foregroundColor(DatesDesign.Colors.textPrimary)
                        }
                    }
                } else {
                    Text("No specific date set")
                        .font(.system(size: 15, weight: .medium, ))
                        .foregroundColor(DatesDesign.Colors.textSecondary)
                }
            }
            .padding(DatesDesign.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .datesCard(elevation: .base)
        }
    }
    
    private var vibeAndStatusSection: some View {
        HStack(spacing: DatesDesign.Spacing.sm) {
            VStack(alignment: .leading, spacing: DatesDesign.Spacing.md) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DatesDesign.Colors.accent)
                    
                    DatesDesign.Typography.heading3("Vibe")
                }
                
                HStack(spacing: DatesDesign.Spacing.xs) {
                    Text(vibeEmojiString(plan.vibe))
                        .font(.system(size: 20))
                    
                    Text(plan.vibe.label)
                        .font(.system(size: 15, weight: .semibold, ))
                        .foregroundColor(DatesDesign.Colors.textPrimary)
                }
                .padding(.horizontal, DatesDesign.Spacing.md)
                .padding(.vertical, DatesDesign.Spacing.sm)
                .background(vibeColor(plan.vibe).opacity(0.12))
                .cornerRadius(DatesDesign.Radius.pill)
            }
            .padding(DatesDesign.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .datesCard(elevation: .base)
        }
    }
    
    private var statusColor: Color {
        switch plan.status {
        case .idea: return .orange
        case .planned: return .green
        case .completed: return .purple
        case .archived: return .gray
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: DatesDesign.Spacing.md) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DatesDesign.Colors.accent)
                
                DatesDesign.Typography.heading3("Notes")
            }
            
            if !plan.notes.isEmpty {
                Text(plan.notes)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(DatesDesign.Colors.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No notes added")
                    .font(.system(size: 15, weight: .medium, ))
                    .foregroundColor(DatesDesign.Colors.textTertiary)
                    .italic()
            }
        }
        .padding(DatesDesign.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .datesCard(elevation: .base)
    }
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Photos", systemImage: "photo.stack")
                    .font(.headline)
                
                Spacer()
                
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                    Label("Add Photos", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }
            
            if !plan.photoURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(plan.photoURLs, id: \.self) { url in
                            AsyncImage(url: URL(string: url)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 200, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 200, height: 200)
                                    .overlay {
                                        ProgressView()
                                    }
                            }
                        }
                    }
                }
            } else {
                Text("No photos yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .onChange(of: selectedPhotos) { newPhotos in
            // Handle photo selection
            // In a real app, you'd upload these to a server
            // For now, we'll just clear the selection
            selectedPhotos = []
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Created")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(plan.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Last updated")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(plan.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Helper functions
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
    
    private func vibeEmojiString(_ vibe: DateVibe) -> String {
        return vibeEmoji(vibe)
    }
}
