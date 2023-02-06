//
//  MapViewController.swift
//  YeolmokTravel
//
//  Created by 김동욱 on 2023/02/03.
//

import UIKit
import MapKit
import CoreLocation

struct AnnotatedCoordinate {
    let title: String
    let coordinate: CLLocationCoordinate2D
}

final class MapViewController: UIViewController {
    // MARK: - Properties
    private var annotatedCoordinates: [AnnotatedCoordinate]
    private lazy var coordinatePointer = PointerConstants.initialValue
    
    init(_ annotatedCoordinates: [AnnotatedCoordinate]) {
        self.annotatedCoordinates = annotatedCoordinates
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented.")
    }
    
    deinit {
        print("deinit: MapViewController")
    }
    
    let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .realistic)
        mapView.layer.cornerRadius = LayoutConstants.cornerRadius
        mapView.layer.borderWidth = AppLayoutConstants.borderWidth
        mapView.layer.borderColor = UIColor.white.cgColor
        mapView.accessibilityLabel = AppTextConstants.mapViewAccessibilityLabel
        return mapView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)
        configure()
        animateCameraToCenter()
        addAnnotation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.frame = view.frame
    }
}

extension MapViewController {
    func updateCoordinates(_ annotatedCoordinates: [AnnotatedCoordinate]) {
        self.annotatedCoordinates = annotatedCoordinates
    }
    
    func animateCameraToCenter() {
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut) { [self] in
            guard let span = calculateSpan() else { return }
            mapView.region = MKCoordinateRegion(
                center: calculateCenter(),
                span: span
            )
        }
    }
    
    @MainActor func addAnnotation() {
        for annotatedCoordinate in annotatedCoordinates {
            let annotation = MKPointAnnotation()
            annotation.coordinate = annotatedCoordinate.coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    @MainActor func removeAnnotation() {
        mapView.removeAnnotations(mapView.annotations)
    }
    
    // reduce
    private func calculateCenter() -> CLLocationCoordinate2D {
        var latitude: CLLocationDegrees = 0
        var longitude: CLLocationDegrees = 0
        
        for annotatedCoordinate in annotatedCoordinates {
            latitude += annotatedCoordinate.coordinate.latitude
            longitude += annotatedCoordinate.coordinate.longitude
        }
        
        latitude /= Double(annotatedCoordinates.count)
        longitude /= Double(annotatedCoordinates.count)
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // 최대 차이 + 조금
    private func calculateSpan() -> MKCoordinateSpan? {
        if annotatedCoordinates.count == 1 {
            return MKCoordinateSpan(
                latitudeDelta: CoordinateConstants.mapSpan,
                longitudeDelta: CoordinateConstants.mapSpan
            )
        }
        
        guard let minLatitude = annotatedCoordinates.min(by: { $0.coordinate.latitude < $1.coordinate.latitude }) else { return nil }
        guard let maxLatitude = annotatedCoordinates.max(by: { $0.coordinate.latitude < $1.coordinate.latitude }) else { return nil }
        let latitudeGap = maxLatitude.coordinate.latitude - minLatitude.coordinate.latitude + CoordinateConstants.littleSpan
        
        guard let minLongitude = annotatedCoordinates.min(by: { $0.coordinate.longitude < $1.coordinate.longitude }) else { return nil }
        guard let maxLongitude = annotatedCoordinates.max(by: { $0.coordinate.longitude < $1.coordinate.longitude }) else { return nil }
        let longitudeGap = maxLongitude.coordinate.latitude - minLongitude.coordinate.latitude + CoordinateConstants.littleSpan
        
        return MKCoordinateSpan(latitudeDelta: latitudeGap, longitudeDelta: longitudeGap)
    }
}

extension MapViewController: MKMapViewDelegate {
    func configure() {
        mapView.delegate = self
    }
    
    func animateCamera(to coordinate: CLLocationCoordinate2D) {
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut) { [self] in
            mapView.region = MKCoordinateRegion(center: coordinate,
                                                      latitudinalMeters: CoordinateConstants.pointSpan,
                                                      longitudinalMeters: CoordinateConstants.pointSpan)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKAnnotationView()
        guard let order = findCoordinate(annotation.coordinate),
                order <= CoordinateConstants.maximumNumberOfCoordinates else { return nil }
        annotationView.image = createImage(order + 1)
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didDeselect annotation: MKAnnotation) {
        animateCameraToCenter()
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        animateCamera(to: annotation.coordinate)
    }
    
    private func findCoordinate(_ coordinate: CLLocationCoordinate2D) -> Int? {
        annotatedCoordinates.firstIndex {
            $0.coordinate.latitude == coordinate.latitude && $0.coordinate.longitude == coordinate.longitude
        }
    }
    
    private func createImage(_ order: Int) -> UIImage? {
        let iconName = "\(order).circle.fill"
        return UIImage(systemName: iconName)
    }
}

// MARK: - Pointer control
extension MapViewController {
    func initalizePointer() {
        coordinatePointer = PointerConstants.initialValue
    }
    
    func increasePointer() {
        coordinatePointer = (coordinatePointer + 1) % annotatedCoordinates.count
    }
    
    func decreasePointer() {
        if coordinatePointer <= 0 {
            coordinatePointer = annotatedCoordinates.count - 1
        } else {
            coordinatePointer = (coordinatePointer - 1) % annotatedCoordinates.count
        }
    }
    
    func animateCameraToPointer() {
        animateCamera(to: annotatedCoordinates[coordinatePointer].coordinate)
    }
}

private enum CoordinateConstants {
    static let mapSpan: CLLocationDegrees = 0.005
    static let littleSpan: CLLocationDegrees = 0.02
    static let pointSpan: CLLocationDistance = 300
    static let maximumNumberOfCoordinates = 50
}

private enum PointerConstants {
    static let initialValue = -1
}

private enum LayoutConstants {
    static let cornerRadius: CGFloat = 10
}
