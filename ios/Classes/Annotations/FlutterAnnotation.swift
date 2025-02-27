//
//  FlutterAnnotation.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 07.03.20.
//

import Foundation
import MapKit

class FlutterAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var id :String!
    var title: String?
    var subtitle: String?
    var backgroundColor: String?
    var isChildAnnotation: Bool
    var clusteringIdentifier: String?
    var infoWindowConsumesTapEvents: Bool = false
    var controlActions: Int = 0
    var image: UIImage?
    var alpha: Double?
    var anchor: Offset = Offset()
    var isDraggable: Bool?
    var wasDragged: Bool = false
    var isVisible: Bool? = true
    var calloutOffset: Offset = Offset()
    var icon: AnnotationIcon = AnnotationIcon.init()
    
    public init(fromDictionary annotationData: Dictionary<String, Any>, registrar: FlutterPluginRegistrar) {
        let position :Array<Double> = annotationData["position"] as! Array<Double>
        let infoWindow :Dictionary<String, Any> = annotationData["infoWindow"] as! Dictionary<String, Any>
        let lat: Double = position[0]
        let long: Double = position[1]
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        self.title = infoWindow["title"] as? String
        self.subtitle = infoWindow["snippet"] as? String
        self.infoWindowConsumesTapEvents = infoWindow["consumesTapEvents"] as? Bool ?? false
        self.controlActions = annotationData["controlActions"] as? Int ?? 0
        self.id = annotationData["annotationId"] as? String
        self.backgroundColor = annotationData["backgroundColor"] as? String
        self.isVisible = annotationData["visible"] as? Bool
        self.isDraggable = annotationData["draggable"] as? Bool
        self.clusteringIdentifier = annotationData["clusteringIdentifier"] as? String
        self.isChildAnnotation = (annotationData["isChildAnnotation"] as? Bool) ?? false
        if let alpha: Double = annotationData["alpha"] as? Double {
            self.alpha = alpha
        }
        
        if let imageJSON: Array<Any> = annotationData["image"] as? Array<Any> {
            self.image = FlutterAnnotation.getImage(imageData: imageJSON)
        }
        
        if let anchorJSON: Array<Double> = annotationData["anchor"] as? Array<Double> {
            self.anchor = Offset(from: anchorJSON)
        }
        
        if let iconData: Array<Any> = annotationData["icon"] as? Array<Any> {
            self.icon = FlutterAnnotation.getAnnotationIcon(iconData: iconData, registrar: registrar, annotationId: id)
        }
        
        if let calloutOffsetJSON = infoWindow["anchor"] as? Array<Double> {
            self.calloutOffset = Offset(from: calloutOffsetJSON)
        }
    }
    
    enum ImageType {
        case ASSETS, CUSTOM_FROM_BYTES
    }
    
    static private func getImage(imageData: Array<Any>) -> UIImage? {
        let imageTypeMap: Dictionary<String, ImageType> = ["fromAssetImage": .ASSETS, "fromBytes": .CUSTOM_FROM_BYTES]
        var image: UIImage?
        let imageType: ImageType = imageTypeMap[imageData[0] as! String] ?? .CUSTOM_FROM_BYTES
        
        if imageType == .ASSETS {
            if let data = imageData[1] as? String {
                image = UIImage(named: data)
            }
        } else if imageType == .CUSTOM_FROM_BYTES {
            if let data = imageData[1] as? FlutterStandardTypedData {
                image = UIImage(data: data.data)
            }
        }
        return image
    }
    
    static private func getAnnotationIcon(iconData: Array<Any>, registrar: FlutterPluginRegistrar, annotationId: String) -> AnnotationIcon {
        let iconTypeMap: Dictionary<String, IconType> = ["fromAssetImage": .CUSTOM_FROM_ASSET, "fromBytes": .CUSTOM_FROM_BYTES, "defaultAnnotation": .PIN, "markerAnnotation": .MARKER, "pointAnnotation": .POINT]
        var icon: AnnotationIcon
        let iconType: IconType = iconTypeMap[iconData[0] as! String] ?? .PIN
        var scaleParam: CGFloat?
        
        if iconType == .CUSTOM_FROM_ASSET {
            let assetPath: String = iconData[1] as! String
            scaleParam = CGFloat(iconData[2] as? Double ?? 1.0)
            icon = AnnotationIcon(named: registrar.lookupKey(forAsset: assetPath), id: annotationId, iconScale: scaleParam)
        } else if iconType == .CUSTOM_FROM_BYTES {
            icon = AnnotationIcon(fromBytes: iconData[1] as! FlutterStandardTypedData, id: annotationId)
        }else {
            icon = AnnotationIcon(id: annotationId, iconType: iconType)
        }
        return icon
    }
    
    static func == (lhs: FlutterAnnotation, rhs: FlutterAnnotation) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.clusteringIdentifier == rhs.clusteringIdentifier && lhs.subtitle == rhs.subtitle && lhs.image == rhs.image && lhs.alpha == rhs.alpha && lhs.isDraggable == rhs.isDraggable && lhs.wasDragged == rhs.wasDragged && lhs.isVisible == rhs.isVisible && lhs.icon == rhs.icon && lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude && lhs.infoWindowConsumesTapEvents == rhs.infoWindowConsumesTapEvents && lhs.anchor == rhs.anchor && lhs.calloutOffset == rhs.calloutOffset && lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude && lhs.backgroundColor == rhs.backgroundColor && lhs.controlActions == rhs.controlActions && lhs.image == rhs.image && rhs.isChildAnnotation == lhs.isChildAnnotation
    }
    
    static func != (lhs: FlutterAnnotation, rhs: FlutterAnnotation) -> Bool {
        return !(lhs == rhs)
    }
}

struct Offset {
    let x: Double
    let y: Double
    
    public init(from json: Array<Double>) {
        self.x = json[0]
        self.y = json[1]
    }
    
    public init() {
        self.x = 0
        self.y = 0
    }
    
    static func == (lhs: Offset, rhs: Offset) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    static func != (lhs: Offset, rhs: Offset) -> Bool {
        return !(lhs == rhs)
    }
}
