import Foundation
import CoreData


struct VocabularyToAdd {
    let text: String
    let translation: String
    let pronunciation: String
}
struct VocabularyReviewResult {
    let vocabulary: Vocabulary
    let time_spent: Int
    let created_at: Date
}

class VocabularyReviewManager {
    let config: Config

    static let intervals: [TimeInterval] = [
        0,                  // 当天
        24 * 3600,         // 1天后
        4 * 24 * 3600,     // 4天后
        7 * 24 * 3600,     // 7天后
        15 * 24 * 3600,    // 15天后
        30 * 24 * 3600     // 30天后
    ]

    init(config: Config) {
        self.config = config
    }

    func calculateNextReview(result: VocabularyReviewResult) {
        let ctx = config.store.container.viewContext

        let vocabulary = result.vocabulary
        let time_spent = result.time_spent

        let mastery_level = {
            if vocabulary.last_review_at == nil {
                return 1
            }
            if time_spent < 3 {
                return 5
            } else if time_spent < 5 {
                return 4
            } else if time_spent < 8 {
                return 3
            } else if time_spent < 12 {
                return 2
            } else {
                return 1
            }
        }()
        let prev_mastery_level = vocabulary.mastery_level
        vocabulary.mastery_level = Int16(mastery_level)
        vocabulary.last_review_at = result.created_at
        let interval = VocabularyReviewManager.intervals[mastery_level]

        vocabulary.next_review_at = Date().addingTimeInterval(interval)

        let history = VocabularyReviewHistory(context: ctx)
        history.id = UUID()
        history.created_at = result.created_at
        history.vocabulary_id = vocabulary.id
        history.time_spent = Int16(time_spent)
        history.score = Int16(mastery_level)
        history.prev_score = prev_mastery_level
        ctx.insert(history)

        try! ctx.save()
    }

    func addVocabulary(vocabulary: VocabularyToAdd) {
        let ctx = config.store.container.viewContext
        let record = Vocabulary(context: ctx)
        record.id = UUID()
        record.created_at = Date()
        record.text = vocabulary.text
        record.translation = vocabulary.translation
        record.pronunciation = vocabulary.pronunciation
        record.next_review_at = Date().addingTimeInterval(24 * 3600)
        ctx.insert(record)
        try! ctx.save()
    }

    // 获取今天需要复习的单词
    func getTodayReviewWords() async throws -> [Vocabulary] {
        let ctx = config.store.container.viewContext
        let now = Date()
        let req = NSFetchRequest<Vocabulary>(entityName: "Vocabulary")
        req.predicate = NSPredicate(format: "next_review_at <= %@", now as CVarArg)
        req.sortDescriptors = [NSSortDescriptor(key: "mastery_level", ascending: true)]
        return try await ctx.fetch(req)
    }

    // 获取指定日期需要复习的单词
    func getReviewWords(for date: Date) async throws -> [Vocabulary] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let ctx = config.store.container.viewContext
        let req = NSFetchRequest<Vocabulary>(entityName: "Vocabulary")
        req.predicate = NSPredicate(
            format: "next_review_at >= %@ AND next_review_at < %@",
            startOfDay as CVarArg,
            endOfDay as CVarArg
        )
        req.sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: true)]
        return try await ctx.fetch(req)
    }
    
    // 获取未来几天的复习统计
    func getReviewStats(daysCount: Int = 6) async throws -> [(Date, Int)] {
        var stats: [(Date, Int)] = []
        let calendar = Calendar.current
        let now = Date()
        
        for dayOffset in 0..<daysCount {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: now)!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let ctx = config.store.container.viewContext
            let req = NSFetchRequest<NSNumber>(entityName: "Vocabulary")
            req.predicate = NSPredicate(
                format: "next_review_at >= %@ AND next_review_at < %@",
                startOfDay as CVarArg,
                endOfDay as CVarArg
            )
            
            // 使用 count 表达式
            req.resultType = .countResultType
            
            let count = try await ctx.count(for: req)
            stats.append((date, count))
        }
        
        return stats
    }
}
