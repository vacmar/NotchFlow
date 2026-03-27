import AppKit
import SwiftUI

@MainActor
final class ArtworkColorExtractor {
    private static let cache = NSCache<NSString, NSColor>()

    static func dominantColor(from artworkImage: NSImage?) -> Color? {
        guard let image = artworkImage else { return nil }
        
        let cacheKey = image.hashValue.description as NSString
        if let cachedColor = cache.object(forKey: cacheKey) {
            return Color(cachedColor)
        }

        let resizedImage = image.resized(to: NSSize(width: 64, height: 64))
        let ciImage = resizedImage.ciImage ?? resizedImage.coreImageRepresentation()

        guard let ciImage = ciImage else {
            return nil
        }

        var redSum: CGFloat = 0
        var greenSum: CGFloat = 0
        var blueSum: CGFloat = 0
        var pixelCount: CGFloat = 0

        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        let dataProvider = cgImage.dataProvider
        guard let pixelData = dataProvider?.data else {
            return nil
        }

        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData as CFData)
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = cgImage.bytesPerRow

        for y in 0..<height {
            for x in 0..<width {
                let pixelInfo = (bytesPerRow * y) + (x * bytesPerPixel)
                
                let red = CGFloat(data[pixelInfo]) / 255.0
                let green = CGFloat(data[pixelInfo + 1]) / 255.0
                let blue = CGFloat(data[pixelInfo + 2]) / 255.0

                redSum += red
                greenSum += green
                blueSum += blue
                pixelCount += 1
            }
        }

        guard pixelCount > 0 else { return nil }

        let averageRed = redSum / pixelCount
        let averageGreen = greenSum / pixelCount
        let averageBlue = blueSum / pixelCount

        let dominantColor = NSColor(
            red: averageRed,
            green: averageGreen,
            blue: averageBlue,
            alpha: 1.0
        )

        cache.setObject(dominantColor, forKey: cacheKey)
        return Color(dominantColor)
    }

    static func complementaryColor(_ color: Color) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        NSColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return Color(
            red: 1 - red,
            green: 1 - green,
            blue: 1 - blue
        )
    }
}

extension NSImage {
    func resized(to newSize: NSSize) -> NSImage {
        let img = NSImage(size: newSize)
        
        img.lockFocus()
        let ctx = NSGraphicsContext.current
        ctx?.imageInterpolation = .high
        self.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: self.size),
            operation: .copy,
            fraction: 1.0
        )
        img.unlockFocus()
        
        return img
    }

    var ciImage: CIImage? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return CIImage(bitmapImageRep: bitmapImage)
    }

    func coreImageRepresentation() -> CIImage? {
        guard let tiffData = self.tiffRepresentation else { return nil }
        return CIImage(data: tiffData)
    }
}
