//
//  ClusterableAnnotationView.swift
//  apple_maps_flutter
//
//  Created by Felix Junghans on 19.08.21.
//

import MapKit

@available(iOS 11.0, *)
class ClusterableAnnotationView: MKAnnotationView {

    var lastAnnotation: FlutterAnnotation?

    override var annotation: MKAnnotation? {
        didSet {
            guard let mapItem = annotation as? FlutterAnnotation, mapItem != lastAnnotation else { return }
            image = mapItem.icon.image
            clusteringIdentifier = mapItem.clusteringIdentifier
            lastAnnotation = mapItem
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
