import CoreData
import SwiftUI
import CoreData

struct ChatSessionWithLatestBox: Identifiable {
    var id: UUID { session.id! }
	var session: ChatSession
	var box: ChatBox?
}
func FetchSessions(params: ListHelperParams, config: Config) -> [ChatSessionWithLatestBox] {
	let ctx = config.store.container.viewContext
    var request = NSFetchRequest<ChatSession>(entityName: "ChatSession")
	
	request.fetchLimit = params.pageSize
	request.fetchOffset = params.pageSize * (params.page - 1)

	request.sortDescriptors = [] as! [NSSortDescriptor]
	
	if params.sorts.count > 0 {
		for (key, value) in params.sorts {
			print("[BIZ]FetchSessions sort: \(key) \(value)")
            request.sortDescriptors!.append(NSSortDescriptor(key: key, ascending: value == "asc"))
		}
	}
	
	do {
		let fetchedSessions = try ctx.fetch(request)
		var list: [ChatSessionWithLatestBox] = []

		for session in fetchedSessions {
			let request = NSFetchRequest<ChatBox>(entityName: "ChatBox")
			request.predicate = NSPredicate(format: "%K == %@", argumentArray: ["session_id", session.id])
			request.sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false)]
			request.fetchBatchSize = 1
            var box: ChatBox? = nil
            if let boxes = try? ctx.fetch(request) {
                box = boxes.first
            }
			list.append(ChatSessionWithLatestBox(session: session, box: box))
		}
		return list
		
	} catch {
		print("[Sessions] Error fetching sessions: \(error)")
		return []
	}
}
