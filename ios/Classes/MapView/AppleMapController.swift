//
//  AppleMapController.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 03.09.19.
//

import Foundation
import MapKit

public class AppleMapController: NSObject, FlutterPlatformView {
    var mapView: FlutterMapView
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    var initialCameraPosition: [String: Any]
    var options: [String: Any]
    var onCalloutTapGestureRecognizer: UITapGestureRecognizer?
    var currentlySelectedAnnotation: String?
    var snapShotOptions: MKMapSnapshotter.Options = MKMapSnapshotter.Options()
    var snapShot: MKMapSnapshotter?
    var hideChildAnnotations: Bool = true
    
    let availableCaps: Dictionary<String, CGLineCap> = [
        "buttCap": CGLineCap.butt,
        "roundCap": CGLineCap.round,
        "squareCap": CGLineCap.square
    ]
    
    let availableJointTypes: Array<CGLineJoin> = [
        CGLineJoin.miter,
        CGLineJoin.bevel,
        CGLineJoin.round
    ]
    
    var isClusteringEnabled = false
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withargs args: Dictionary<String, Any> ,withId id: Int64) {
        self.options = args["options"] as! [String: Any]
        self.channel = FlutterMethodChannel(name: "apple_maps_plugin.luisthein.de/apple_maps_\(id)", binaryMessenger: registrar.messenger())
        
        self.mapView = FlutterMapView(channel: channel, options: options)
        self.registrar = registrar
        
        self.initialCameraPosition = args["initialCameraPosition"]! as! Dictionary<String, Any>
        self.isClusteringEnabled = args["clusteringEnabled"] as! Bool
        super.init()
        
        self.mapView.delegate = self
        if isClusteringEnabled {
            if #available(iOS 11.0, *) {
                mapView.register(
                    ClusterAnnotationView.self,
                    forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
            }
        }
        
        
        self.mapView.setCenterCoordinate(initialCameraPosition, animated: false)
        self.setMethodCallHandlers()
        
        if let annotationsToAdd: NSArray = args["annotationsToAdd"] as? NSArray {
            self.annotationsToAdd(annotations: annotationsToAdd)
        }
        if let polylinesToAdd: NSArray = args["polylinesToAdd"] as? NSArray {
            self.addPolylines(polylineData: polylinesToAdd)
        }
        if let polygonsToAdd: NSArray = args["polygonsToAdd"] as? NSArray {
            self.addPolygons(polygonData: polygonsToAdd)
        }
        if let circlesToAdd: NSArray = args["circlesToAdd"] as? NSArray {
            self.addCircles(circleData: circlesToAdd)
        }
        
        self.onCalloutTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.calloutTapped(_:)))
    }
    
    deinit {
        self.removeAllAnnotations()
        self.removeAllCircles()
        self.removeAllPolygons()
        self.removeAllPolylines()
    }
    
    public func view() -> UIView {
        return mapView
    }
    
    @objc func calloutTapped(_ sender: UITapGestureRecognizer? = nil) {
        if self.currentlySelectedAnnotation != nil {
            self.channel.invokeMethod("infoWindow#onTap", arguments: ["annotationId": self.currentlySelectedAnnotation!])
        }
    }
    
    private func setMethodCallHandlers() {
        channel.setMethodCallHandler({ [unowned self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if let args :Dictionary<String, Any> = call.arguments as? Dictionary<String,Any> {
                switch(call.method) {
                case "annotations#update":
                    self.annotationUpdate(args: args)
                    result(nil)
                    break
                case "annotations#showInfoWindow":
                    self.showAnnotation(with: args["annotationId"] as! String)
                    break
                case "annotations#hideInfoWindow":
                    self.hideAnnotation(with: args["annotationId"] as! String)
                    break
                case "annotations#isInfoWindowShown":
                    result(self.isAnnotationSelected(with: args["annotationId"] as! String))
                    break
                case "polylines#update":
                    self.polylineUpdate(args: args)
                    result(nil)
                    break
                case "polygons#update":
                    self.polygonUpdate(args: args)
                    result(nil)
                    break
                case "circles#update":
                    self.circleUpdate(args: args)
                    result(nil)
                    break
                case "map#update":
                    self.mapView.interpretOptions(options: args["options"] as! Dictionary<String, Any>)
                    break
                case "camera#animate":
                    self.animateCamera(args: args)
                    result(nil)
                    break
                case "camera#move":
                    self.moveCamera(args: args)
                    result(nil)
                    break
                case "camera#convert":
                    self.cameraConvert(args: args, result: result)
                    break
                default:
                    result(FlutterMethodNotImplemented)
                    break
                }
            } else {
                switch call.method {
                case "map#getVisibleRegion":
                    result(self.mapView.getVisibleRegion())
                    break
                case "map#getCenter":
                    let coordinate = self.mapView.centerCoordinate
                    result(["latitude": coordinate.latitude, "longitude": coordinate.longitude])
                    break
                case "map#isCompassEnabled":
                    if #available(iOS 9.0, *) {
                        result(self.mapView.showsCompass)
                    } else {
                        result(false)
                    }
                    break
                case "map#isPitchGesturesEnabled":
                    result(self.mapView.isPitchEnabled)
                    break
                case "map#isScrollGesturesEnabled":
                    result(self.mapView.isScrollEnabled)
                    break
                case "map#isZoomGesturesEnabled":
                    result(self.mapView.isZoomEnabled)
                    break
                case "map#isRotateGesturesEnabled":
                    result(self.mapView.isRotateEnabled)
                    break
                case "map#isMyLocationButtonEnabled":
                    result(self.mapView.isMyLocationButtonShowing ?? false)
                    break
                case "map#takeSnapshot":
                    self.takeSnapshot(onCompletion: { (snapshot: FlutterStandardTypedData?, error: Error?) -> Void in
                        result(snapshot ?? error)
                    })
                case "map#getMinMaxZoomLevels":
                    result([self.mapView.minZoomLevel, self.mapView.maxZoomLevel])
                    break
                case "camera#getZoomLevel":
                    result(self.mapView.calculatedZoomLevel)
                    break
                case "showAnnotations":
                    self.showAnnotations()
                    result(nil)
                    break
                default:
                    result(FlutterMethodNotImplemented)
                    break
                }
            }
        })
    }
    
    private func showAnnotations() -> Void {
        let annotations = mapView.annotations.filter { annotation in
            if let flutterAnnotation = annotation as? FlutterAnnotation {
                // if((flutterAnnotation.isChildAnnotation && mapView.zoomLevel > 19.0) || (!flutterAnnotation.isChildAnnotation && mapView.zoomLevel <= 19.0)) {
                //     return true
                // }
                if(flutterAnnotation.isChildAnnotation) {
                    return false;
                } else {
                    return true;
                }
            }
            return false
        }
        mapView.showAnnotations(annotations, animated: true)
    }
    
    private func annotationUpdate(args: Dictionary<String, Any>) -> Void {
        if let annotationsToAdd = args["annotationsToAdd"] as? NSArray {
            if annotationsToAdd.count > 0 {
                self.annotationsToAdd(annotations: annotationsToAdd)
            }
        }
        if let annotationsToChange = args["annotationsToChange"] as? NSArray {
            if annotationsToChange.count > 0 {
                self.annotationsToChange(annotations: annotationsToChange)
            }
        }
        if let annotationsToDelete = args["annotationIdsToRemove"] as? NSArray {
            if annotationsToDelete.count > 0 {
                self.annotationsIdsToRemove(annotationIds: annotationsToDelete)
            }
        }
    }
    
    private func polygonUpdate(args: Dictionary<String, Any>) -> Void {
        if let polyligonsToAdd: NSArray = args["polygonsToAdd"] as? NSArray {
            self.addPolygons(polygonData: polyligonsToAdd)
        }
        if let polygonsToChange: NSArray = args["polygonsToChange"] as? NSArray {
            self.changePolygons(polygonData: polygonsToChange)
        }
        if let polygonsToRemove: NSArray = args["polygonIdsToRemove"] as? NSArray {
            self.removePolygons(polygonIds: polygonsToRemove)
        }
    }
    
    private func polylineUpdate(args: Dictionary<String, Any>) -> Void {
        if let polylinesToAdd: NSArray = args["polylinesToAdd"] as? NSArray {
            self.addPolylines(polylineData: polylinesToAdd)
        }
        if let polylinesToChange: NSArray = args["polylinesToChange"] as? NSArray {
            self.changePolylines(polylineData: polylinesToChange)
        }
        if let polylinesToRemove: NSArray = args["polylineIdsToRemove"] as? NSArray {
            self.removePolylines(polylineIds: polylinesToRemove)
        }
    }
    
    private func circleUpdate(args: Dictionary<String, Any>) -> Void {
        if let circlesToAdd: NSArray = args["circlesToAdd"] as? NSArray {
            self.addCircles(circleData: circlesToAdd)
        }
        if let circlesToChange: NSArray = args["circlesToChange"] as? NSArray {
            self.changeCircles(circleData: circlesToChange)
        }
        if let circlesToRemove: NSArray = args["circleIdsToRemove"] as? NSArray {
            self.removeCircles(circleIds: circlesToRemove)
        }
    }
    
    private func moveCamera(args: Dictionary<String, Any>) -> Void {
        let positionData :Dictionary<String, Any> = self.toPositionData(data: args["cameraUpdate"] as! Array<Any>, animated: true)
        if !positionData.isEmpty {
            guard let _ = positionData["moveToBounds"] else {
                self.mapView.setCenterCoordinate(positionData, animated: true)
                return
            }
            self.mapView.setBounds(positionData, animated: true)
        }
    }
    
    private func animateCamera(args: Dictionary<String, Any>) -> Void {
        let positionData :Dictionary<String, Any> = self.toPositionData(data: args["cameraUpdate"] as! Array<Any>, animated: true)
        if !positionData.isEmpty {
            guard let _ = positionData["moveToBounds"] else {
                self.mapView.setCenterCoordinate(positionData, animated: true)
                return
            }
            self.mapView.setBounds(positionData, animated: true)
        }
    }
    
    private func cameraConvert(args: Dictionary<String, Any>, result: FlutterResult) -> Void {
        guard let annotation = args["annotation"] as? Array<Double> else {
            result(nil)
            return
        }
        let point = self.mapView.convert(CLLocationCoordinate2D(latitude: annotation[0] , longitude: annotation[1]), toPointTo: self.view())
        result(["point": [point.x, point.y]])
    }
    
    private func toPositionData(data: Array<Any>, animated: Bool) -> Dictionary<String, Any> {
        var positionData: Dictionary<String, Any> = [:]
        if let update: String = data[0] as? String {
            switch(update) {
            case "newCameraPosition":
                if let _positionData : Dictionary<String, Any> = data[1] as? Dictionary<String, Any> {
                    positionData = _positionData
                }
            case "newLatLng":
                if let _positionData : Array<Any> = data[1] as? Array<Any> {
                    positionData = ["target": _positionData]
                }
            case "newLatLngZoom":
                if let _positionData: Array<Any> = data[1] as? Array<Any> {
                    let zoom: Double = data[2] as? Double ?? 0
                    positionData = ["target": _positionData, "zoom": zoom]
                }
            case "newLatLngBounds":
                if let _positionData: Array<Any> = data[1] as? Array<Any> {
                    let padding: Double = data[2] as? Double ?? 0
                    positionData = ["target": _positionData, "padding": padding, "moveToBounds": true]
                }
            case "zoomBy":
                if let zoomBy: Double = data[1] as? Double {
                    mapView.zoomBy(zoomBy: zoomBy, animated: animated)
                }
            case "zoomTo":
                if let zoomTo: Double = data[1] as? Double {
                    mapView.zoomTo(newZoomLevel: zoomTo, animated: animated)
                }
            case "zoomIn":
                mapView.zoomIn(animated: animated)
            case "zoomOut":
                mapView.zoomOut(animated: animated)
            default:
                positionData = [:]
            }
            return positionData
        }
        return [:]
    }
}


extension AppleMapController: MKMapViewDelegate {
    public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        //   if(mapView.zoomLevel > 19.0 && hideChildAnnotations) {
        //       let annotations = mapView.annotations
        //       annotations.forEach { annotation in
        //           if #available(iOS 11.0, *) {
        //               if((annotation as? FlutterAnnotation)?.isChildAnnotation ?? false) {
        //                   mapView.view(for: annotation)?.isHidden = false
        //               } else {
        //                   mapView.view(for: annotation)?.isHidden = true
        //               }
        //           } else {
        //               // Fallback on earlier versions
        //           }
        //       }
        //       hideChildAnnotations = false;
        //   } else if (mapView.zoomLevel <= 19.0 && !hideChildAnnotations) {
        //       let annotations = mapView.annotations
        //       annotations.forEach { annotation in
        //           if #available(iOS 11.0, *) {
        //               if((annotation as? FlutterAnnotation)?.isChildAnnotation ?? false) {
        //                   mapView.view(for: annotation)?.isHidden = true
        //               } else {
        //                   mapView.view(for: annotation)?.isHidden = false
        //               }
        //           } else {
        //               // Fallback on earlier versions
        //           }
        //       }
        //       hideChildAnnotations = true;
        //   }
        //
    }
    
    // onIdle
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.channel.invokeMethod("camera#onIdle", arguments: "")
    }
    
    // onMoveStarted
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.channel.invokeMethod("camera#onMoveStarted", arguments: "")
    }
    
    //  public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)  {
    //      if let annotation :FlutterAnnotation = view.annotation as? FlutterAnnotation  {
    //          if annotation.infoWindowConsumesTapEvents {
    //              view.addGestureRecognizer(self.onCalloutTapGestureRecognizer!)
    //          }
    //          self.currentlySelectedAnnotation = annotation.id
    //          self.onAnnotationClick(annotation: annotation)
    //      }
    //  }
    
    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)  {
        let annotationCandidate: MKAnnotation?
        print("didSelectView called")
        
        if #available(iOS 11.0, *) {
            if let cluster = view.annotation as? MKClusterAnnotation {
                annotationCandidate = cluster.memberAnnotations.first
            } else {
                annotationCandidate = view.annotation
            }
        } else {
            annotationCandidate = view.annotation
        }
        
        guard let annotation :FlutterAnnotation = annotationCandidate as? FlutterAnnotation else  { return }
        
        if annotation.infoWindowConsumesTapEvents {
            view.addGestureRecognizer(self.onCalloutTapGestureRecognizer!)
        }
        self.currentlySelectedAnnotation = annotation.id
        self.onAnnotationClick(annotation: annotation)
    }
    
    public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        self.currentlySelectedAnnotation = nil
        view.removeGestureRecognizer(self.onCalloutTapGestureRecognizer!)
    }
    
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !isClusteringEnabled else {
            if let flutterAnnotation = annotation as? FlutterAnnotation {
                if #available(iOS 11.0, *) {
                    self.mapView.register(ClusterableAnnotationView.self, forAnnotationViewWithReuseIdentifier: flutterAnnotation.id)
                    let view = self.mapView.dequeueReusableAnnotationView(withIdentifier: flutterAnnotation.id, for: annotation)
                    (view as! ClusterableAnnotationView).setVisibility(zoom: mapView.zoomLevel, annotation: flutterAnnotation)
                    return view
                }
            }
            return nil
        }
        if annotation is MKUserLocation {
            return nil
        } else if let flutterAnnotation = annotation as? FlutterAnnotation {
            return self.getAnnotationView(annotation: flutterAnnotation)
        }
        return nil
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is FlutterPolyline {
            return self.polylineRenderer(overlay: overlay)
        } else if overlay is FlutterPolygon {
            return self.polygonRenderer(overlay: overlay)
        } else if overlay is FlutterCircle {
            return self.circleRenderer(overlay: overlay)
        }
        return MKOverlayRenderer()
    }
}

extension AppleMapController {
    private func takeSnapshot(onCompletion: @escaping (FlutterStandardTypedData?, Error?) -> Void) {
        snapShotOptions.region = self.mapView.region
        snapShotOptions.mapType = self.mapView.mapType
        snapShotOptions.pointOfInterestFilter = self.mapView.pointOfInterestFilter
        snapShotOptions.size = CGSize(width: UIScreen.main.bounds.width < UIScreen.main.bounds.height ? UIScreen.main.bounds.width - 16 : UIScreen.main.bounds.height - 16, height: UIScreen.main.bounds.width < UIScreen.main.bounds.height ? UIScreen.main.bounds.width - 16 : UIScreen.main.bounds.height - 16)
        snapShotOptions.scale = UIScreen.main.scale
        
        let snapshotter = MKMapSnapshotter(options: snapShotOptions)
        snapshotter.start { [weak self] (snapshot: MKMapSnapshot?, error: Error?) -> Void in
            guard error == nil, let snapshot = snapshot else { return }
            
            UIGraphicsBeginImageContextWithOptions(snapshot.image.size, true, snapshot.image.scale)
            snapshot.image.draw(at: CGPoint.zero)
            
            let titleAttributes = self?.titleAttributes()
            for annotation in (self?.mapView.annotations)! {
                let point: CGPoint = snapshot.point(for: annotation.coordinate)
                if let customPin = customPin {
                    self?.drawPin(point: point, annotation: annotation)
                }
                if let title = annotation.title as? String {
                    self?.drawTitle(title: title,
                                    at: point,
                                    attributes: titleAttributes!)
                }
            }
            let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
            if let imageData = compositeImage {
                onCompletion(FlutterStandardTypedData.init(bytes: imageData), nil)
            } else {
                onCompletion(nil, error)
            }
        }
    }
    
    private func drawTitle(title: String,
                           at point: CGPoint,
                           attributes: [NSAttributedStringKey: NSObject]) {
        let titleSize = title.size(withAttributes: attributes)
        title.draw(with: CGRect(
                    x: point.x - titleSize.width / 2.0,
                    y: point.y + 1,
                    width: titleSize.width,
                    height: titleSize.height),
                   options: .usesLineFragmentOrigin,
                   attributes: attributes,
                   context: nil)
    }
    
    private func titleAttributes() -> [NSAttributedStringKey: NSObject] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let titleFont = UIFont.systemFont(ofSize: 10, weight: UIFont.Weight.semibold)
        let attrs = [NSAttributedStringKey.font: titleFont,
                     NSAttributedStringKey.paragraphStyle: paragraphStyle]
        return attrs
    }
    
    private func drawPin(point: CGPoint, annotation: MKAnnotation) {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "test")
        annotationView.contentMode = .scaleAspectFit
        annotationView.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        annotationView.drawHierarchy(in: CGRect(
            x: point.x - annotationView.bounds.size.width / 2.0,
            y: point.y - annotationView.bounds.size.height,
            width: annotationView.bounds.width,
            height: annotationView.bounds.height),
                                     afterScreenUpdates: true)
    }
}
