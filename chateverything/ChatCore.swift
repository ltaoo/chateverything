// import Foundation

// class ChatCore {
//     static func fetchSeasonList(page: Int32 = 1, pageSize: Int32 = 20, name: String = "") -> String {
//         let cName = name.cString(using: .utf8)
//         let result = fetch_season(page, pageSize, cName)
//         let resultString = String(cString: result)
//         free_string(result)
//         return resultString
//     }
    
//     static func parseSeasonList(_ jsonString: String) -> [Season]? {
//         guard let data = jsonString.data(using: .utf8) else { return nil }
//         do {
//             let response = try JSONDecoder().decode(ListResponse.self, from: data)
//             return response.data
//         } catch {
//             print("Error parsing season list: \(error)")
//             return nil
//         }
//     }
// }

// // MARK: - Data Models
// struct ListResponse: Codable {
//     let data: [Season]
//     let page: Int
// }

// struct Season: Codable, Identifiable {
//     let id: String
//     let mediaType: String
//     let name: String
//     let posterPath: String
//     let overview: String
//     let seasonNumber: Int
//     let airDate: String
//     let genres: [Genre]
//     let originCountry: [String]
//     let voteAverage: Double
//     let episodeCount: Int
//     let curEpisodeCount: Int
//     let actors: [Actor]
    
//     enum CodingKeys: String, CodingKey {
//         case id
//         case mediaType = "type"
//         case name
//         case posterPath = "poster_path"
//         case overview
//         case seasonNumber = "season_number"
//         case airDate = "air_date"
//         case genres
//         case originCountry = "origin_country"
//         case voteAverage = "vote_average"
//         case episodeCount = "episode_count"
//         case curEpisodeCount = "cur_episode_count"
//         case actors
//     }
// }

// struct Genre: Codable {
//     let value: Int
//     let label: String
// }

// struct Actor: Codable {
//     let id: String
//     let name: String
// } 