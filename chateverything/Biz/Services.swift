import CoreData
import SwiftUI

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

    request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
        NSPredicate(format: "hidden == false"),
        NSPredicate(format: "hidden == nil")
    ])

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
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "%K == %@", argumentArray: ["session_id", session.id])
            ])
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

struct ChatBoxWithPayload: Identifiable {
    var id: UUID { box.id! }
    var box: ChatBox
    var payload: BoxPayloadTypes
}

func FetchBoxesOfSession(params: ListHelperParams, config: Config) -> [ChatBoxWithPayload] {
    let ctx = config.store.container.viewContext

    let request = NSFetchRequest<ChatBox>(entityName: "ChatBox")
    let search = params.search

    if search.count > 0 {
        for (key, value) in params.search {
            request.predicate = NSPredicate(format: "%K == %@", argumentArray: [key, value])
        }
    }

    request.fetchLimit = params.pageSize
    request.fetchOffset = params.pageSize * (params.page - 1)

    request.sortDescriptors = [] as! [NSSortDescriptor]

    if params.sorts.count > 0 {
        for (key, value) in params.sorts {
            request.sortDescriptors!.append(NSSortDescriptor(key: key, ascending: value == "asc"))
        }
    }

    let store = config.store

    do {
        let fetchedBoxes = try ctx.fetch(request)
        var list: [ChatBoxWithPayload] = []

        for box in fetchedBoxes {
            if box.type == "message" {
                let req = NSFetchRequest<ChatMsgContent>(entityName: "ChatMsgContent")
                req.predicate = NSPredicate(
                    format: "%K == %@", argumentArray: ["id", box.payload_id])
                if let message = try! store.container.viewContext.fetch(req).first {
                    let payload = BoxPayloadTypes.message(message)
                    list.append(ChatBoxWithPayload(box: box, payload: payload))
                }
            }
            if box.type == "audio" {
                let req = NSFetchRequest<ChatMsgAudio>(entityName: "ChatMsgAudio")
                req.predicate = NSPredicate(
                    format: "%K == %@", argumentArray: ["id", box.payload_id])
                if let audio = try! store.container.viewContext.fetch(req).first {
                    let payload = BoxPayloadTypes.audio(audio)
                    list.append(ChatBoxWithPayload(box: box, payload: payload))
                }
            }
            if box.type == "puzzle" {
                let req = NSFetchRequest<ChatMsgPuzzle>(entityName: "ChatMsgPuzzle")
                req.predicate = NSPredicate(
                    format: "%K == %@", argumentArray: ["id", box.payload_id])
                if let puzzle = try! store.container.viewContext.fetch(req).first {
                    let payload = BoxPayloadTypes.puzzle(puzzle)
                    list.append(ChatBoxWithPayload(box: box, payload: payload))
                }
            }
            if box.type == "image" {
                let req = NSFetchRequest<ChatMsgImage>(entityName: "ChatMsgImage")
                req.predicate = NSPredicate(
                    format: "%K == %@", argumentArray: ["id", box.payload_id])
                if let image = try! store.container.viewContext.fetch(req).first {
                    let payload = BoxPayloadTypes.image(image)
                    list.append(ChatBoxWithPayload(box: box, payload: payload))
                }
            }
            if box.type == "video" {
                let req = NSFetchRequest<ChatMsgVideo>(entityName: "ChatMsgVideo")
                req.predicate = NSPredicate(
                    format: "%K == %@", argumentArray: ["id", box.payload_id])
                if let video = try! store.container.viewContext.fetch(req).first {
                    let payload = BoxPayloadTypes.video(video)
                    list.append(ChatBoxWithPayload(box: box, payload: payload))
                }
            }
            if box.type == "error" {
                let req = NSFetchRequest<ChatMsgError>(entityName: "ChatMsgError")
                req.predicate = NSPredicate(
                    format: "%K == %@", argumentArray: ["id", box.payload_id])
                if let error = try! store.container.viewContext.fetch(req).first {
                    let payload = BoxPayloadTypes.error(error)
                    list.append(ChatBoxWithPayload(box: box, payload: payload))
                }
            }
            if box.type == "tipText" {
                let req = NSFetchRequest<ChatMsgTipText>(entityName: "ChatMsgTipText")
                req.predicate = NSPredicate(
                    format: "%K == %@", argumentArray: ["id", box.payload_id])
                if let tipText = try! store.container.viewContext.fetch(req).first {
                    let payload = BoxPayloadTypes.tipText(tipText)
                    list.append(ChatBoxWithPayload(box: box, payload: payload))
                }
            }
            if box.type == "time" {
                let req = NSFetchRequest<ChatMsgTime>(entityName: "ChatMsgTime")
                req.predicate = NSPredicate(
                    format: "%K == %@", argumentArray: ["id", box.payload_id])
                if let time = try! store.container.viewContext.fetch(req).first {
                    let payload = BoxPayloadTypes.time(time)
                    list.append(ChatBoxWithPayload(box: box, payload: payload))
                }
            }

            if box.type == "dictionary" {
                let req = NSFetchRequest<ChatMsgDictionary>(entityName: "ChatMsgDictionary")
                req.predicate = NSPredicate(
                    format: "%K == %@", argumentArray: ["id", box.payload_id])
                if let dictionary = try! store.container.viewContext.fetch(req).first {
                    let payload = BoxPayloadTypes.dictionary(dictionary)
                    list.append(ChatBoxWithPayload(box: box, payload: payload))
                }
            }
        }
        return list

    } catch {
        return []
    }
}
