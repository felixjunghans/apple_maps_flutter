//
//  ClusterableAnnotationView.swift
//  apple_maps_flutter
//
//  Created by Felix Junghans on 19.08.21.
//

import MapKit

let supportedIcons : Dictionary<String, String> = [
    "rutsche": "rutsche",
    "schaukel": "schaukel",
    "wippe": "wippe",
]

@available(iOS 11.0, *)
class ClusterableAnnotationView: MKMarkerAnnotationView {
    
    var lastAnnotation: FlutterAnnotation?
    override var annotation: MKAnnotation? {
        didSet {
            guard let mapItem = annotation as? FlutterAnnotation, mapItem != lastAnnotation else { return }
            glyphImage = mapItem.image
            displayPriority = .required
            if(mapItem.backgroundColor != nil) {
                markerTintColor = colorWithHexString(hexString: mapItem.backgroundColor!)
            }
            clusteringIdentifier = mapItem.clusteringIdentifier
        }
    }
    
    func setVisibility(zoom: Double, annotation: FlutterAnnotation) {
        if((annotation.isChildAnnotation && zoom <= 17.0) || (annotation.isChildAnnotation && zoom > 17.0)) {
            isHidden = true
        }
    }
}

@available(iOS 11.0, *)
final class ClusterAnnotationView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        didSet {
            guard let cluster = annotation as? MKClusterAnnotation, let firstAnnotation = cluster.memberAnnotations.first as? FlutterAnnotation else { return }
            titleVisibility = .hidden
            subtitleVisibility = .hidden
        }
    }
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .required
    }
}

private func drawMarker() -> UIImage {
    if #available(iOS 10.0, *) {
        let size = 60.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size + 10))
        let image = renderer.image { _ in
            // Fill full circle with wholeColor
            UIColor.systemGreen.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size, height: size), cornerRadius: 10).fill()
            
            let heightWidth = 60
            let path = UIBezierPath()
            
            path.move(to: CGPoint(x: size / 2 - 10, y: size))
            path.addLine(to: CGPoint(x:heightWidth/2, y: heightWidth + 10))
            path.addLine(to: CGPoint(x: size / 2 + 10, y: size))
            path.addLine(to: CGPoint(x:size / 2 - 10, y: size))
            path.close()
            path.fill()
            
            // Finally draw count text vertically and horizontally centered
            let attributes = [ NSAttributedString.Key.foregroundColor: UIColor.black,
                               NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)]
            let text = "Ok"
            let size = text.size(withAttributes: attributes)
            let rect = CGRect(x: 20 - size.width / 2, y: 20 - size.height / 2, width: size.width, height: size.height)
            text.draw(in: rect, withAttributes: attributes)
        }
        return image
    } else {
        // Fallback on earlier versions
    }
    return UIImage()
}

func colorWithHexString(hexString: String) -> UIColor {
    var colorString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
    colorString = colorString.replacingOccurrences(of: "#", with: "").uppercased()
    
    print(colorString)
    let alpha: CGFloat = 1.0
    let red: CGFloat = colorComponentFrom(colorString: colorString, start: 0, length: 2)
    let green: CGFloat = colorComponentFrom(colorString: colorString, start: 2, length: 2)
    let blue: CGFloat = colorComponentFrom(colorString: colorString, start: 4, length: 2)
    
    let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
    return color
}

func colorComponentFrom(colorString: String, start: Int, length: Int) -> CGFloat {
    let startIndex = colorString.index(colorString.startIndex, offsetBy: start)
    let endIndex = colorString.index(startIndex, offsetBy: length)
    let subString = colorString[startIndex..<endIndex]
    let fullHexString = length == 2 ? subString : "\(subString)\(subString)"
    var hexComponent: UInt32 = 0
    
    guard Scanner(string: String(fullHexString)).scanHexInt32(&hexComponent) else {
        return 0
    }
    let hexFloat: CGFloat = CGFloat(hexComponent)
    let floatValue: CGFloat = CGFloat(hexFloat / 255.0)
    return floatValue
}
