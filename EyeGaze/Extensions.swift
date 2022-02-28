//
//  Extensions.swift
//  EyeGaze
//
//  Created by Chris Nixon on 28/02/2022.
//

import Foundation
import PDFKit

// Exposing scrollView component
extension PDFView {
    public var scrollView: UIScrollView? {
        for view in self.subviews {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
        }
        return nil
    }
}

extension TimeInterval{
    
    init?(dispatchTimeInterval: DispatchTimeInterval) {
        switch dispatchTimeInterval {
        case .seconds(let value):
            self = Double(value)
        case .milliseconds(let value):
            self = Double(value) / 1_000
        case .microseconds(let value):
            self = Double(value) / 1_000_000
        case .nanoseconds(let value):
            self = Double(value) / 1_000_000_000
        case .never:
            return nil
        @unknown default:
            fatalError()
        }
    }
    
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        
        var formatString = ""
        if hours == 0 {
            if(minutes < 10) {
                formatString = "%2d:%0.2d"
            }else {
                formatString = "%0.2d:%0.2d"
            }
            return String(format: formatString,minutes,seconds)
        }else {
            formatString = "%2d:%0.2d:%0.2d"
            return String(format: formatString,hours,minutes,seconds)
        }
    }
}

extension UIImage {
    public func resized(to target: CGSize) -> UIImage {
        let ratio = min(
            target.height / size.height, target.width / size.width
        )
        let new = CGSize(
            width: size.width * ratio, height: size.height * ratio
        )
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

extension Float {
    func toIntTruncated() -> Int {
        let maxTruncated  = min(self, Float(Int.max).nextDown)
        let bothTruncated = max(maxTruncated, Float(Int.min))
        return Int(bothTruncated)
    }
}

extension Collection where Self.Iterator.Element: RandomAccessCollection {
    // PRECONDITION: `self` must be rectangular, i.e. every row has equal size.
    func transposed() -> [[Self.Iterator.Element.Iterator.Element]] {
        guard let firstRow = self.first else { return [] }
        return firstRow.indices.map { index in
            self.map{ $0[index] }
        }
    }
}

enum PageTurningImplementation: Int {
    case scrolling
    case singleAnimation
    case doubleAnimation
}

public enum FaceCropResult {
    case success((Double, Double, [CGImage]))
    case notFound
    case failure(Error)
}
