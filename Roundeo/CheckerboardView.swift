import SwiftUI

struct CheckerboardView: View {
    private let squareSize: CGFloat = 8

    var body: some View {
        Canvas { context, size in
            let cols = Int(ceil(size.width / squareSize))
            let rows = Int(ceil(size.height / squareSize))

            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(white: 0.25)))

            for row in 0..<rows {
                for col in 0..<cols where (row + col) % 2 == 0 {
                    let rect = CGRect(
                        x: CGFloat(col) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    context.fill(Path(rect), with: .color(Color(white: 0.18)))
                }
            }
        }
    }
}
