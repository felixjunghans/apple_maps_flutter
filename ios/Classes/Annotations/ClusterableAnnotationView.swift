//
//  ClusterableAnnotationView.swift
//  apple_maps_flutter
//
//  Created by Felix Junghans on 19.08.21.
//

import MapKit

@available(iOS 11.0, *)
class ClusterableAnnotationView: MKMarkerAnnotationView {

    var lastAnnotation: FlutterAnnotation?
    let label = UILabel.init(frame: CGRect(x: 0, y: 70, width: 60, height: 15))
    
    override var annotation: MKAnnotation? {
        didSet {
            guard let mapItem = annotation as? FlutterAnnotation, mapItem != lastAnnotation else { return }
            glyphImage = mapItem.image
            clusteringIdentifier = mapItem.clusteringIdentifier
        }
    }
}

@available(iOS 11.0, *)
final class ClusterAnnotationView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        didSet {
            guard let cluster = annotation as? MKClusterAnnotation, let firstAnnotation = cluster.memberAnnotations.first as? FlutterAnnotation else { return }
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
