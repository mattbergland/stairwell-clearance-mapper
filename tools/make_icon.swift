import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Generates a 1024x1024 app icon: warm background, white staircase rising
// left to right, dark grand-piano silhouette on its side riding the stairs.
let size = 1024
let space = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: size, height: size,
                          bitsPerComponent: 8, bytesPerRow: 0,
                          space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
else { fatalError("no context") }

// Background: deep warm brown gradient feel via two fills
ctx.setFillColor(red: 0.16, green: 0.12, blue: 0.09, alpha: 1)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
ctx.setFillColor(red: 0.24, green: 0.17, blue: 0.11, alpha: 1)
ctx.fillEllipse(in: CGRect(x: -200, y: -200, width: 1424, height: 1424))

// Stairs (light wood), stepping up left -> right from the bottom-left.
ctx.setFillColor(red: 0.87, green: 0.78, blue: 0.62, alpha: 1)
let steps = 7
let stepW = size / steps
let stepH = 110
for i in 0..<steps {
    ctx.fill(CGRect(x: i * stepW, y: size - (i + 1) * stepH - 120,
                    width: stepW, height: (i + 1) * stepH + 120))
}

// Grand piano silhouette on its side: rounded body block + tail curve,
// standing on the second step from the left.
let px = stepW + 30
let py = size - 2 * stepH - 120 - 380
ctx.setFillColor(red: 0.10, green: 0.08, blue: 0.07, alpha: 1)
let body = CGPath(roundedRect: CGRect(x: px, y: py, width: 620, height: 300),
                  cornerWidth: 60, cornerHeight: 60, transform: nil)
ctx.addPath(body)
ctx.fillPath()
// tail taper
ctx.move(to: CGPoint(x: px + 620, y: py + 40))
ctx.addCurve(to: CGPoint(x: px + 720, y: py + 200),
             control1: CGPoint(x: px + 720, y: py + 60),
             control2: CGPoint(x: px + 720, y: py + 160))
ctx.addLine(to: CGPoint(x: px + 620, y: py + 240))
ctx.closePath()
ctx.fillPath()
// keyboard lip
ctx.setFillColor(red: 0.95, green: 0.90, blue: 0.80, alpha: 1)
ctx.fill(CGRect(x: px - 14, y: py + 90, width: 40, height: 120))

guard let image = ctx.makeImage() else { fatalError("no image") }
let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("no dest") }
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("write failed") }
print("wrote \(url.path)")
