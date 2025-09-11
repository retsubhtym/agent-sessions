import Foundation

enum PrettyJSON {
    static func prettyPrinted(_ json: String) -> String {
        guard let data = json.data(using: .utf8) else { return json }
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [])
            let pretty = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
            return String(data: pretty, encoding: .utf8) ?? json
        } catch {
            return json
        }
    }
}
