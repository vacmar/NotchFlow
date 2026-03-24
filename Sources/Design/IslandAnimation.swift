import SwiftUI

enum IslandAnimation {
    static let expand = Animation.spring(response: 0.26, dampingFraction: 0.82)
    static let collapse = Animation.spring(response: 0.32, dampingFraction: 0.92)
    static let controlsFade = Animation.easeOut(duration: 0.24)
}
