import UIKit
import AVFoundation

/// Hard exclusions so GlossyGlass never covers video / media playback surfaces
/// (DM video messages, 1v/2v viewers, reels player, camera, etc.).
@objc public final class GlassMediaExclusion: NSObject {

    @objc public static func isMediaSurface(_ view: UIView) -> Bool {
        var current: UIView? = view
        var depth = 0
        while let v = current, depth < 12 {
            if matches(v) { return true }
            // AVPlayerLayer attached
            if v.layer.sublayers?.contains(where: { $0 is AVPlayerLayer }) == true {
                return true
            }
            if v.layer is AVPlayerLayer { return true }
            current = v.superview
            depth += 1
        }
        return false
    }

    @objc public static func matches(_ view: UIView) -> Bool {
        let name = NSStringFromClass(type(of: view)).lowercased()
        let label = (view.accessibilityLabel ?? "").lowercased()
        let blob = name + " " + label

        let keys = [
            "avplayer", "avplayerlayer", "avplayerview",
            "videoplayer", "videoview", "igvideo", "igplayback",
            "playback", "mediaviewer", "mediaplayer",
            "reelplayer", "reelsplayer", "sundialplayer",
            "storyplayer", "storyviewer", // full story video surface
            "photoplayer", "onceview", "ephemeral",
            "disappearing", "viewonce", "1v", "2v",
            "igdmcinema", "cinemaview", "videocontainer",
            "igtv", "liveviewer", "broadcast",
            "camerapreview", "capturevideo",
            "skplayer", "fbvideo", "metafvideo"
        ]
        if keys.contains(where: { blob.contains($0) }) { return true }

        // Full-screen-ish dark views that host video (common DM open-video chrome)
        if view.bounds.width > 280, view.bounds.height > 400 {
            if name.contains("player") || name.contains("video") || name.contains("cinema") {
                return true
            }
        }
        return false
    }

    /// True if applying glass would cover a video (host or ancestor is media).
    @objc public static func shouldSkipGlass(for view: UIView) -> Bool {
        if isMediaSurface(view) { return true }
        // Don't glass large full-screen containers that are likely media presenters
        if view.bounds.width >= UIScreen.main.bounds.width - 4,
           view.bounds.height >= UIScreen.main.bounds.height * 0.55 {
            let n = NSStringFromClass(type(of: view)).lowercased()
            if n.contains("player") || n.contains("video") || n.contains("media")
                || n.contains("viewer") || n.contains("cinema") || n.contains("reel") {
                return true
            }
        }
        return false
    }
}
