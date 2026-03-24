import SwiftUI

enum IslandAnimation {
    static let expand = Animation.spring(response: 0.26, dampingFraction: 0.82)
    static let collapse = Animation.spring(response: 0.22, dampingFraction: 0.88)
    static let controlsFade = Animation.easeOut(duration: 0.18)
}
