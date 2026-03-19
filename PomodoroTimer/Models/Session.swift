import Foundation

struct Session: Codable {
    let label: String
    let sessionType: SessionType
    let startTime: Date
    let duration: Int
}
