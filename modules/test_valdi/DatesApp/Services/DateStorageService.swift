import Foundation

@MainActor
class DateStorageService: ObservableObject {
    @Published var plans: [DatePlan] = []
    @Published var isOnline = false
    @Published var errorMessage: String?
    @Published var isPaired = false
    
    private let apiClient = APIClient.shared
    private let coreData = CoreDataManager.shared
    let notificationService = NotificationService()
    private var syncTimer: Timer?
    
    init() {
        // Migrate from UserDefaults if needed
        coreData.migrateFromUserDefaults()
        
        loadPlans()
        Task {
            await syncWithBackend()
            await checkPairingStatus()
            await notificationService.checkAuthorization()
            await notificationService.scheduleNotifications(for: plans)
            startAutoSync()
        }
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    private func startAutoSync() {
        // Poll every 10 seconds when logged in
        guard APIConfig.accessToken != nil else { return }
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.syncWithBackend()
            }
        }
    }
    
    func checkPairingStatus() async {
        guard APIConfig.accessToken != nil else {
            isPaired = false
            return
        }
        
        do {
            let status = try await apiClient.getCoupleStatus()
            isPaired = status.isPaired
        } catch {
            isPaired = false
        }
    }
    
    func loadPlans() {
        plans = coreData.fetchAll()
    }
    
    func savePlan(_ plan: DatePlan) {
        var updatedPlan = plan
        updatedPlan.updatedAt = Date()
        
        // Save to CoreData
        coreData.save(updatedPlan)
        
        // Reload from CoreData
        loadPlans()
        
        // Schedule notification if it's a planned date
        Task {
            await syncPlanToBackend(updatedPlan)
            if updatedPlan.status == .planned {
                await notificationService.scheduleNotification(for: updatedPlan)
            } else {
                notificationService.cancelNotification(for: updatedPlan.id)
            }
        }
    }
    
    func deletePlan(_ id: String) {
        coreData.delete(id)
        loadPlans()
        
        // Cancel notification and delete from backend
        Task {
            notificationService.cancelNotification(for: id)
            await deletePlanFromBackend(id)
        }
    }
    
    func clearAll() {
        coreData.deleteAll()
        loadPlans()
    }
    
    var nextPlan: DatePlan? {
        plans.first { $0.status == .planned }
    }
    
    var ideasCount: Int {
        plans.filter { $0.status == .idea }.count
    }
    
    var upcomingPlans: [DatePlan] {
        coreData.fetchUpcoming()
    }
    
    func filterByStatus(_ status: DateStatus) -> [DatePlan] {
        coreData.fetchByStatus(status)
    }
    
    func filterByVibe(_ vibe: DateVibe) -> [DatePlan] {
        coreData.fetchByVibe(vibe)
    }
    
    // MARK: - Backend Sync
    
    func onLogin() async {
        await syncWithBackend()
        await checkPairingStatus()
        startAutoSync()
    }
    
    func onLogout() {
        syncTimer?.invalidate()
        syncTimer = nil
        isOnline = false
        isPaired = false
    }
    
    func refreshFromBackend() async {
        await syncWithBackend()
        await checkPairingStatus()
    }
    
    func syncWithBackend() async {
        do {
            let remotePlans = try await apiClient.listDates()
            
            // Save remote plans to CoreData
            for remotePlan in remotePlans {
                coreData.save(remotePlan)
            }
            
            // Reload from CoreData
            loadPlans()
            
            isOnline = true
            errorMessage = nil
        } catch APIError.unauthorized {
            // User not logged in - use local storage only
            isOnline = false
            errorMessage = nil
        } catch {
            // Network error - continue with local storage
            isOnline = false
            errorMessage = "Offline mode"
        }
    }
    
    private func syncPlanToBackend(_ plan: DatePlan) async {
        guard APIConfig.accessToken != nil else { return }
        
        do {
            // Check if plan exists on server
            let existingPlan = try? await apiClient.getDate(id: plan.id)
            
            if existingPlan != nil {
                _ = try await apiClient.updateDate(id: plan.id, plan)
            } else {
                _ = try await apiClient.createDate(plan)
            }
            isOnline = true
        } catch {
            // Silently fail - plan is saved locally
            isOnline = false
        }
    }
    
    private func deletePlanFromBackend(_ id: String) async {
        guard APIConfig.accessToken != nil else { return }
        
        do {
            try await apiClient.deleteDate(id: id)
            isOnline = true
        } catch {
            // Silently fail - plan is deleted locally
            isOnline = false
        }
    }
}

