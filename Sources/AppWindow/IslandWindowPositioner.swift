import AppKit

struct IslandWindowPositioner {
    private let topOverlap: CGFloat = 15

    func topCenteredFrame(for size: CGSize, screen: NSScreen?) -> CGRect {
        guard let screen else {
            return CGRect(origin: .zero, size: size)
        }

        let screenFrame = screen.frame
        let x = screenFrame.midX - (size.width / 2)
        let y = screenFrame.maxY - size.height + topOverlap

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}
