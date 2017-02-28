//
//  MomentBackgroundHeaderView.swift
//  Flybits
//
//  Created by chu on 2015-09-01.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

private enum ViewType {
    case image
    case map
}

private var CurrentViewType: ViewType = .map

class MomentBackgroundHeaderView: UIView {
    var useZoneImage: Bool = false {
        didSet {
            CurrentViewType = .image
            points = nil
        }
    }

//    var pullToRefresh: PullToRefresh = PullToRefresh(frame: CGRectMake(0, 0, 0, 0))
    fileprivate var mapView: MKMapView!
    fileprivate var imageView: UIImageView!
    fileprivate var polygon:MKPolygon?
    fileprivate var polygonColor: UIColor?
    fileprivate var snapshottedImage: UIImage? {
        didSet {
            imageView?.image = snapshottedImage
        }
    }

    var points: [CLLocation]? {
        didSet {

            if case CurrentViewType = ViewType.image {
                setupImageView()
            } else {
                setupMapView()
            }
        }
    }
    
    weak var image: UIImage? {
        didSet {
            if useZoneImage {
                imageView?.image = image
            }
        }
    }

    fileprivate func setupMapView() {

        if (mapView == nil) {
            mapView = MKMapView()
            mapView.isUserInteractionEnabled = false
            mapView.isZoomEnabled = false
            mapView.isScrollEnabled = false
            mapView.isRotateEnabled = false
            mapView.isPitchEnabled = false
            mapView.showsPointsOfInterest = false

            mapView.delegate = self
            if #available(iOS 9.0, *) {
                mapView.mapType = MKMapType.satelliteFlyover
                mapView.showsTraffic = false
                mapView.showsScale = false
            } else {
                // Fallback on earlier versions
                mapView.mapType = MKMapType.standard
            }
            addSubview(mapView)
        }

        guard let points = points else {
            mapView.setVisibleMapRect(MKMapRectWorld, animated: false)
            return
        }

        var coordinates:[CLLocationCoordinate2D] = []
        for p in points {
            coordinates.append(p.coordinate)
        }

//        mapView.removeOverlays(mapView.overlays)
        
        if let polygon = polygon {
            mapView.remove(polygon)
        }
        
        self.polygon = MKPolygon(coordinates: &coordinates, count: coordinates.count)
        guard let polygon = self.polygon else {
            mapView.setVisibleMapRect(MKMapRectWorld, animated: false)
            return
        }
        mapView.add(polygon, level: MKOverlayLevel.aboveRoads)
        if #available(iOS 9.0, *) {
            rotate(0, duration: 2)
        } else {
            mapView.setVisibleMapRect(polygon.boundingMapRect, animated: true)
        }
    }

    fileprivate func setupImageView() {
        if imageView == nil {
            imageView = UIImageView()
            imageView.contentMode = UIViewContentMode.scaleAspectFill
            imageView.layer.masksToBounds = true
            addSubview(imageView)
        }

        guard let points = points else {
            imageView.image = nil
            return
        }

        if useZoneImage {
            self.imageView.image = image
        } else {
            var coordinates:[CLLocationCoordinate2D] = []
            for p in points {
                coordinates.append(p.coordinate)
            }
            self.polygon = MKPolygon(coordinates: &coordinates, count: coordinates.count)
            snapshot()
        }
    }

    fileprivate func snapshot() {
        guard let polygon = polygon else {
            snapshottedImage = nil
            return
        }

        guard let points = self.points else {
            snapshottedImage = nil
            return
        }
        guard !self.bounds.size.equalTo(CGSize.zero) else {
            snapshottedImage = nil
            return
        }

        let options = MKMapSnapshotOptions()
        options.mapRect = polygon.boundingMapRect
        options.scale = UIScreen.main.scale
        options.size = self.bounds.size
        if #available(iOS 9.0, *) {
            options.mapType = MKMapType.satelliteFlyover
        } else {
            // Fallback on earlier versions
            options.mapType = MKMapType.standard
        }
        let cam = options.camera
        cam.pitch = 0
        cam.heading = 90
        cam.altitude = 1000
        options.camera = cam

        let snapper = MKMapSnapshotter(options: options)
        snapper.start (completionHandler: { [weak self](snap, error) -> Void in
            if let snap = snap {
                
                let image = snap.image
                UIGraphicsBeginImageContextWithOptions(image.size, true, UIScreen.main.scale);
                image.draw(at: CGPoint.zero)
                
                if let context = UIGraphicsGetCurrentContext() {
                    
                    context.setStrokeColor(UIColor ( red: 0.5068, green: 0.5068, blue: 0.5068, alpha: 1.0 ).cgColor);
                    //                CGContextSetFillColorWithColor(context, UIColor.blueColor().CGColor)
                    context.setLineWidth(1.0);
                    context.beginPath();
                    
                    for (i,p) in points.enumerated() {
                        
                        let point = snap.point(for: p.coordinate)
                        if(i==0)
                        {
                            context.move(to: CGPoint(x: point.x, y: point.y))
                        }
                        else{
                            context.addLine(to: CGPoint(x: point.x, y: point.y))
                        }
                    }
                    context.fillPath()
                    context.strokePath()
                    self?.snapshottedImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                }
                
            } else {
                self?.snapshottedImage = nil
            }
        })
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        if case CurrentViewType = ViewType.image {
            setupImageView()
        } else {
            setupMapView()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView?.frame = self.bounds
        self.mapView?.frame = self.bounds
    }
}

extension MKMapSize {
    /// - returns: The area of this MKMapSize object
    func area() -> Double {
        return height * width
    }
}

extension MomentBackgroundHeaderView : MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        var renderer = mapView.renderer(for: overlay) as? MKPolygonRenderer
        if renderer == nil {
            renderer = MKPolygonRenderer(overlay: overlay)
            renderer?.fillColor = (polygonColor ?? UIColor.orange).withAlphaComponent(0.6)
            renderer?.lineWidth = 1
            renderer?.strokeColor = UIColor.brown
        }
        return renderer!
    }

    func rotate(_ pitch: CGFloat, duration: TimeInterval) {


        let options:UIViewAnimationOptions = [UIViewAnimationOptions.allowAnimatedContent, UIViewAnimationOptions.allowUserInteraction, UIViewAnimationOptions.beginFromCurrentState, UIViewAnimationOptions.curveLinear]

        //to change the rotation speed, either inscrease the animation duration or lower the heading angle
        UIView.animate(withDuration: duration, delay: 0, options:options, animations: { [weak self]() -> Void in

            guard let tempSelf = self , tempSelf.polygon != nil else {
                return
            }
            
            let cam = tempSelf.mapView.camera.copy() as! MKMapCamera
            cam.centerCoordinate = tempSelf.polygon!.coordinate
            cam.pitch = pitch //round((15.0 + abs(self.mapView.camera.pitch)) % 45)
//            
            let distance = MKMetersBetweenMapPoints(tempSelf.polygon!.boundingMapRect.origin,
                MKMapPointMake(MKMapRectGetMaxX(tempSelf.polygon!.boundingMapRect), MKMapRectGetMaxY(tempSelf.polygon!.boundingMapRect)))
            let altitude = distance / tan(M_PI*(45/180.0));

            cam.altitude = altitude
            cam.heading = round((10.0 + abs(tempSelf.mapView?.camera.heading ?? 0)).truncatingRemainder(dividingBy: 360.0))
            tempSelf.mapView?.camera = cam
            }, completion: nil)
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard self.polygon != nil else { return }
        if #available(iOS 9.0, *) {
            self.rotate(45, duration:5)
        }
    }
}
