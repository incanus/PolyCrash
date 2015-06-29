import UIKit
import MBXMapKit

class ViewController: UIViewController, MKMapViewDelegate {

    enum OverlayType {
        case Polyline
        case Polygon
    }

    typealias Bounds = (sw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D)

    var map: MKMapView!
    var bounds: Bounds!
    var polygon: MKPolygon!
    var polyline: MKPolyline!

    override func viewDidLoad() {
        super.viewDidLoad()

        bounds = (CLLocationCoordinate2D(latitude: 90, longitude: 180),
            CLLocationCoordinate2D(latitude: -90, longitude: -180))

        map = MKMapView(frame: view.bounds)
        map.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        map.delegate = self
        view.addSubview(map)

        MBXMapKit.setAccessToken("pk.eyJ1IjoianVzdGluIiwiYSI6IlpDbUJLSUEifQ.4mG8vhelFMju6HpIY-Hi5A")
        map.addOverlay(MBXRasterTileOverlay(mapID: "roadtrippers.j3e9lo03"))

        addOverlayWithPointsFile("polygon.txt", ofType: .Polygon)
        addOverlayWithPointsFile("polyline.txt" as NSString, ofType: .Polyline)

        map.region = MKCoordinateRegion(center:
            CLLocationCoordinate2D(latitude: (bounds.ne.latitude + bounds.sw.latitude) / 2,
                longitude: (bounds.ne.longitude + bounds.sw.longitude) / 2),
            span: MKCoordinateSpan(latitudeDelta: bounds.ne.latitude - bounds.sw.latitude,
                longitudeDelta: bounds.ne.longitude - bounds.sw.longitude))

        NSTimer.scheduledTimerWithTimeInterval(1,
            target: self,
            selector: "removePolyline",
            userInfo: nil,
            repeats: true)

        NSTimer.scheduledTimerWithTimeInterval(2,
            target: self,
            selector: "removePolygon",
            userInfo: nil,
            repeats: true)

        NSTimer.scheduledTimerWithTimeInterval(3,
            target: self,
            selector: "addPolyline",
            userInfo: nil,
            repeats: true)

        NSTimer.scheduledTimerWithTimeInterval(4,
            target: self,
            selector: "addPolygon",
            userInfo: nil,
            repeats: true)
    }

    func removePolyline() {
        map.removeOverlay(polyline)
    }

    func removePolygon() {
        map.removeOverlay(polygon)
    }

    func addPolyline() {
        map.addOverlay(polyline)
    }

    func addPolygon() {
        map.addOverlay(polygon)
    }

    func addOverlayWithPointsFile(pointsFile: NSString, ofType type: OverlayType) {
        let (base, ext) = (pointsFile.componentsSeparatedByString(".").first as! String, pointsFile.componentsSeparatedByString(".").last as! String)
        let points = NSString(contentsOfFile: NSBundle.mainBundle().pathForResource(base,
            ofType: ext)!, encoding: NSUTF8StringEncoding,
            error: nil)!.componentsSeparatedByString("\n")
        var coordinates = [CLLocationCoordinate2D]()
        for point in points as! [NSString] {
            if let lat: AnyObject = point.componentsSeparatedByString(",").first,
                lon: AnyObject = point.componentsSeparatedByString(",").last {
                if lat.length > 0 && lon.length > 0 {
                    coordinates.append(CLLocationCoordinate2D(latitude: lat.doubleValue,
                        longitude: lon.doubleValue))
                    if coordinates.last!.latitude < bounds.sw.latitude {
                        bounds.sw.latitude = coordinates.last!.latitude
                    }
                    if coordinates.last!.latitude > bounds.ne.latitude {
                        bounds.ne.latitude = coordinates.last!.latitude
                    }
                    if coordinates.last!.longitude < bounds.sw.longitude {
                        bounds.sw.longitude = coordinates.last!.longitude
                    }
                    if coordinates.last!.longitude > bounds.ne.longitude {
                        bounds.ne.longitude = coordinates.last!.longitude
                    }
                }
            }
        }
        if type == .Polyline {
            map.addOverlay(MKPolyline(coordinates: &coordinates, count: coordinates.count))
            polyline = map.overlays.last! as! MKPolyline
        } else if type == .Polygon {
            map.addOverlay(MKPolygon(coordinates: &coordinates, count: coordinates.count))
            polygon = map.overlays.last! as! MKPolygon
        }
    }

    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MBXRasterTileOverlay {
            return MBXRasterTileRenderer(overlay: overlay)
        } else if overlay is MKPolyline {
            return {
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = UIColor.redColor().colorWithAlphaComponent(0.5)
                renderer.lineWidth = 5
                return renderer
                }()
        } else if overlay is MKPolygon {
            return {
                let renderer = MKPolygonRenderer(overlay: overlay)
                renderer.strokeColor = UIColor.blueColor().colorWithAlphaComponent(0.75)
                renderer.lineWidth = 2
                renderer.fillColor = UIColor.blueColor().colorWithAlphaComponent(0.1)
                return renderer
                }()
        }
        return nil
    }


}
