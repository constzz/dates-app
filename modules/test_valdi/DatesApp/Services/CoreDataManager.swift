import Foundation
import CoreData

@MainActor
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    
    init() {
        // Create model programmatically
        let model = NSManagedObjectModel()
        
        // DatePlanEntity
        let entity = NSEntityDescription()
        entity.name = "DatePlanEntity"
        entity.managedObjectClassName = "DatePlanEntity"
        
        // Attributes
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .stringAttributeType
        
        let userIDAttr = NSAttributeDescription()
        userIDAttr.name = "userID"
        userIDAttr.attributeType = .stringAttributeType
        userIDAttr.isOptional = true
        
        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType
        
        let placeAttr = NSAttributeDescription()
        placeAttr.name = "place"
        placeAttr.attributeType = .stringAttributeType
        
        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = true
        
        let timeAttr = NSAttributeDescription()
        timeAttr.name = "time"
        timeAttr.attributeType = .stringAttributeType
        timeAttr.isOptional = true
        
        let vibeAttr = NSAttributeDescription()
        vibeAttr.name = "vibe"
        vibeAttr.attributeType = .stringAttributeType
        
        let statusAttr = NSAttributeDescription()
        statusAttr.name = "status"
        statusAttr.attributeType = .stringAttributeType
        
        let notesAttr = NSAttributeDescription()
        notesAttr.name = "notes"
        notesAttr.attributeType = .stringAttributeType
        
        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        
        let updatedAtAttr = NSAttributeDescription()
        updatedAtAttr.name = "updatedAt"
        updatedAtAttr.attributeType = .dateAttributeType
        
        let photoURLsAttr = NSAttributeDescription()
        photoURLsAttr.name = "photoURLs"
        photoURLsAttr.attributeType = .binaryDataAttributeType
        photoURLsAttr.isOptional = true
        
        entity.properties = [
            idAttr, userIDAttr, titleAttr, placeAttr, dateAttr, timeAttr,
            vibeAttr, statusAttr, notesAttr, createdAtAttr, updatedAtAttr, photoURLsAttr
        ]
        
        model.entities = [entity]
        
        container = NSPersistentContainer(name: "DatesModel", managedObjectModel: model)
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save Core Data: \(error)")
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    func fetchAll() -> [DatePlan] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "DatePlanEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let entities = try container.viewContext.fetch(request)
            return entities.compactMap { entity in
                guard let id = entity.value(forKey: "id") as? String,
                      let title = entity.value(forKey: "title") as? String,
                      let place = entity.value(forKey: "place") as? String,
                      let vibeRaw = entity.value(forKey: "vibe") as? String,
                      let statusRaw = entity.value(forKey: "status") as? String,
                      let notes = entity.value(forKey: "notes") as? String,
                      let createdAt = entity.value(forKey: "createdAt") as? Date,
                      let updatedAt = entity.value(forKey: "updatedAt") as? Date else {
                    return nil
                }
                
                let photoURLs: [String]
                if let photoData = entity.value(forKey: "photoURLs") as? Data {
                    photoURLs = (try? JSONDecoder().decode([String].self, from: photoData)) ?? []
                } else {
                    photoURLs = []
                }
                
                return DatePlan(
                    id: id,
                    title: title,
                    place: place,
                    date: entity.value(forKey: "date") as? Date,
                    time: entity.value(forKey: "time") as? String,
                    vibe: DateVibe(rawValue: vibeRaw) ?? .easy,
                    status: DateStatus(rawValue: statusRaw) ?? .idea,
                    notes: notes,
                    photoURLs: photoURLs,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
            }
        } catch {
            print("Failed to fetch plans: \(error)")
            return []
        }
    }
    
    func fetchByStatus(_ status: DateStatus) -> [DatePlan] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "DatePlanEntity")
        request.predicate = NSPredicate(format: "status == %@", status.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let entities = try container.viewContext.fetch(request)
            return entities.compactMap { toPlan($0) }
        } catch {
            print("Failed to fetch plans by status: \(error)")
            return []
        }
    }
    
    func fetchByVibe(_ vibe: DateVibe) -> [DatePlan] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "DatePlanEntity")
        request.predicate = NSPredicate(format: "vibe == %@", vibe.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let entities = try container.viewContext.fetch(request)
            return entities.compactMap { toPlan($0) }
        } catch {
            print("Failed to fetch plans by vibe: \(error)")
            return []
        }
    }
    
    func fetchUpcoming() -> [DatePlan] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "DatePlanEntity")
        let now = Date()
        request.predicate = NSPredicate(format: "status == %@ AND date >= %@", DateStatus.planned.rawValue, now as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let entities = try container.viewContext.fetch(request)
            return entities.compactMap { toPlan($0) }
        } catch {
            print("Failed to fetch upcoming plans: \(error)")
            return []
        }
    }
    
    func save(_ plan: DatePlan) {
        // Check if exists
        let request = NSFetchRequest<NSManagedObject>(entityName: "DatePlanEntity")
        request.predicate = NSPredicate(format: "id == %@", plan.id)
        
        do {
            let results = try container.viewContext.fetch(request)
            let entity: NSManagedObject
            
            if let existing = results.first {
                entity = existing
            } else {
                entity = NSEntityDescription.insertNewObject(forEntityName: "DatePlanEntity", into: container.viewContext)
                entity.setValue(plan.id, forKey: "id")
                entity.setValue(plan.createdAt, forKey: "createdAt")
            }
            
            // Update fields
            entity.setValue(plan.photoURLs, forKey: "photoURLs")
            entity.setValue(plan.title, forKey: "title")
            entity.setValue(plan.place, forKey: "place")
            entity.setValue(plan.date, forKey: "date")
            entity.setValue(plan.time, forKey: "time")
            entity.setValue(plan.vibe.rawValue, forKey: "vibe")
            entity.setValue(plan.status.rawValue, forKey: "status")
            entity.setValue(plan.notes, forKey: "notes")
            entity.setValue(plan.updatedAt, forKey: "updatedAt")
            
            save()
        } catch {
            print("Failed to save plan: \(error)")
        }
    }
    
    func delete(_ id: String) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "DatePlanEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let results = try container.viewContext.fetch(request)
            for entity in results {
                container.viewContext.delete(entity)
            }
            save()
        } catch {
            print("Failed to delete plan: \(error)")
        }
    }
    
    func deleteAll() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DatePlanEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try container.viewContext.execute(deleteRequest)
            save()
        } catch {
            print("Failed to delete all plans: \(error)")
        }
    }
    
    // MARK: - Migration
    
    func migrateFromUserDefaults() {
        let key = "dates_mvp_plans"
        guard let data = UserDefaults.standard.data(forKey: key),
              let plans = try? JSONDecoder().decode([DatePlan].self, from: data) else {
            return
        }
        
        print("Migrating \(plans.count) plans from UserDefaults to CoreData")
        
        for plan in plans {
            save(plan)
        }
        
        // Clear UserDefaults after successful migration
        UserDefaults.standard.removeObject(forKey: key)
        print("Migration complete")
    }
    
    private func toPlan(_ entity: NSManagedObject) -> DatePlan? {
        guard let id = entity.value(forKey: "id") as? String,
              let title = entity.value(forKey: "title") as? String,
              let place = entity.value(forKey: "place") as? String,
              let vibeRaw = entity.value(forKey: "vibe") as? String,
              let statusRaw = entity.value(forKey: "status") as? String,
              let notes = entity.value(forKey: "notes") as? String,
              let createdAt = entity.value(forKey: "createdAt") as? Date,
              let updatedAt = entity.value(forKey: "updatedAt") as? Date else {
            return nil
        }
        
        let photoURLs: [String]
        if let photoData = entity.value(forKey: "photoURLs") as? Data {
            photoURLs = (try? JSONDecoder().decode([String].self, from: photoData)) ?? []
        } else {
            photoURLs = []
        }
        
        return DatePlan(
            id: id,
            title: title,
            place: place,
            date: entity.value(forKey: "date") as? Date,
            time: entity.value(forKey: "time") as? String,
            vibe: DateVibe(rawValue: vibeRaw) ?? .easy,
            status: DateStatus(rawValue: statusRaw) ?? .idea,
            notes: notes,
            photoURLs: photoURLs,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
