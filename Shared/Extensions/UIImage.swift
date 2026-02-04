//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

extension UIImage {

    func getTileImage(
        columns: Int,
        rows: Int,
        index: Int
    ) async -> UIImage? {
        let x = index % columns
        let y = index / columns

        // Use integer arithmetic for tile dimensions and positions
        let imageWidth = Int(size.width)
        let imageHeight = Int(size.height)
        let tileWidth = imageWidth / columns
        let tileHeight = imageHeight / rows

        // Calculate the rectangle using integer values
        let rect = CGRect(
            x: x * tileWidth,
            y: y * tileHeight,
            width: tileWidth,
            height: tileHeight
        )

        // Offload cropping to background thread to prevent UI lag during scrubbing
        return await Task.detached(priority: .userInitiated) { [cgImage = self.cgImage] in
            guard let cgImage = cgImage,
                  let croppedCGImage = cgImage.cropping(to: rect) else {
                return nil
            }
            return UIImage(cgImage: croppedCGImage)
        }.value

//        guard index >= 0 else {
//            return nil
//        }
//
//        let imageWidth = size.width
//        let imageHeight = size.height
//
//        let tileWidth = imageWidth / CGFloat(columns)
//        let tileHeight = imageHeight / CGFloat(rows)
//
//        let x = (index % columns)
//        let y = (index / columns)
//
//        let rect = CGRect(
//            x: CGFloat(x) * tileWidth,
//            y: CGFloat(y) * tileHeight,
//            width: tileWidth,
//            height: tileHeight
//        )
//
//        guard rect.maxX <= imageWidth && rect.maxY <= imageHeight else {
//            return nil
//        }
//
//        if let cgImage = cgImage?.cropping(to: rect) {
//            return UIImage(cgImage: cgImage)
//        }
//
//        return nil
    }
}
