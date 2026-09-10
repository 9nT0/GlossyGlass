import Foundation

/// Checks GitHub releases for newer than current (non-blocking)
@objc public class GlassUpdateChecker: NSObject {
    @objc public static let shared = GlassUpdateChecker()
    @objc public private(set) var latestTag: String = ""
    @objc public private(set) var updateAvailable = false
    @objc public private(set) var lastError: String = ""

    private let current = "4.0.0"
    private let apiURL = URL(string: "https://api.github.com/repos/9nT0/GlossyGlass/releases/latest")!

    @objc public func checkAsync(completion: ((Bool, String) -> Void)? = nil) {
        var req = URLRequest(url: apiURL)
        req.setValue("GlossyGlass/4.0", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 8
        URLSession.shared.dataTask(with: req) { data, _, err in
            if let err = err {
                self.lastError = err.localizedDescription
                DispatchQueue.main.async { completion?(false, "") }
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = (json["tag_name"] as? String)?.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            else {
                self.lastError = "parse"
                DispatchQueue.main.async { completion?(false, "") }
                return
            }
            self.latestTag = tag
            self.updateAvailable = Self.isNewer(tag, than: self.current)
            DispatchQueue.main.async {
                completion?(self.updateAvailable, tag)
            }
        }.resume()
    }

    private static func isNewer(_ a: String, than b: String) -> Bool {
        let pa = a.split(separator: ".").compactMap { Int($0) }
        let pb = b.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0
            let y = i < pb.count ? pb[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}
