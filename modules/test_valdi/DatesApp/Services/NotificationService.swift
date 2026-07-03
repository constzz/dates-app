import Foundation
import UserNotifications

@MainActor
class NotificationService: ObservableObject {
    @Published var isAuthorized = false
    
    private let center = UNUserNotificationCenter.current()
    
    init() {
        Task {
            await checkAuthorization()
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    func checkAuthorization() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    func scheduleNotification(for plan: DatePlan) async {
        guard isAuthorized else { return }
        guard plan.status == .planned else { return }
        
        // Remove existing notification for this plan
        center.removePendingNotificationRequests(withIdentifiers: [plan.id])
        
        // Schedule new notification
        guard let date = plan.date else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Date"
        content.body = "\(plan.title) at \(plan.place)"
        if !plan.notes.isEmpty {
            content.subtitle = plan.notes
        }
        content.sound = .default
        content.badge = 1
        
        // Schedule for 1 hour before the date
        let notificationDate = date.addingTimeInterval(-3600)
        
        // Only schedule if date is in the future
        guard notificationDate > Date() else { return }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: plan.id, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            print("Scheduled notification for \(plan.title) at \(notificationDate)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    func cancelNotification(for planID: String) {
        center.removePendingNotificationRequests(withIdentifiers: [planID])
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    func scheduleNotifications(for plans: [DatePlan]) async {
        guard isAuthorized else { return }
        
        // Cancel all existing
        center.removeAllPendingNotificationRequests()
        
        // Schedule notifications for all upcoming planned dates
        for plan in plans where plan.status == .planned && plan.date != nil {
            await scheduleNotification(for: plan)
        }
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
}
