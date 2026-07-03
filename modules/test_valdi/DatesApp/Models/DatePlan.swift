import Foundation

enum DateStatus: String, Codable, CaseIterable {
    case idea
    case planned
    case completed
    case archived
}

enum DateVibe: String, Codable, CaseIterable {
    case easy
    case classic
    case spontaneous
    case adventure
    case relaxed
    case fancy
    
    var label: String {
        switch self {
        case .easy: return "Easy"
        case .classic: return "Classic"
        case .spontaneous: return "Spontaneous"
        case .adventure: return "Adventure"
        case .relaxed: return "Relaxed"
        case .fancy: return "Fancy"
        }
    }
}

struct DatePlan: Identifiable, Codable {
    let id: String
    var title: String
    var place: String
    var date: Date?
    var time: String?
    var vibe: DateVibe
    var status: DateStatus
    var notes: String
    var photoURLs: [String]
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        title: String = "",
        place: String = "",
        date: Date? = nil,
        time: String? = nil,
        vibe: DateVibe = .easy,
        status: DateStatus = .idea,
        notes: String = "",
        photoURLs: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.place = place
        self.date = date
        self.time = time
        self.vibe = vibe
        self.status = status
        self.notes = notes
        self.photoURLs = photoURLs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var formattedTiming: String {
        guard let date = date else {
            return "Not scheduled"
        }
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        let dayName = dayFormatter.string(from: date)
        
        if let time = time {
            return "\(dayName) \(time)"
        }
        
        return dayName
    }
}
