//
//  ViewController.swift
//  TimeConverter
//
//  Created by Samit Shaikh on 3/11/19.
//  Copyright © 2019 Samit Shaikh. All rights reserved.
//

// TODO: Modify the tableviewcells of search panel so it shows region underneath
//       the timezone abbreviation instead of next to the title.
// TODO: Do the actual time conversion stuff and stuff.

import UIKit
import MapKit
import FloatingPanel // https://github.com/SCENEE/FloatingPanel

// MARK: ViewController
class ViewController: UIViewController, FloatingPanelControllerDelegate, CellTapDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {

    // Outlets
    @IBOutlet weak var sideButtons: UIVisualEffectView!
    @IBOutlet weak var searchIconView: UIView!
    @IBOutlet weak var locationIconView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
    var fpc: FloatingPanelController!
    var fpcSearch: FloatingPanelController!
    var fpcSearchShownBefore: Bool = false
    var locationButtonPressedBefore: Bool = false
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.showsUserLocation = false
        
        // Accessing Map View Delegate
        mapView.delegate = self
        
        // Set up long press
        let longPressGestureRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(mapViewLongPress(recogniser:)))
        longPressGestureRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressGestureRecogniser)
        
        // Set up side buttons on the map
        sideButtons.layer.cornerRadius = 10.0
        sideButtons.clipsToBounds = true
        sideButtons.layer.borderWidth = 1
        sideButtons.layer.borderColor = UIColor.opaqueSeparator.cgColor
        sideButtons.frame = CGRect(x: sideButtons.frame.minX, y: ((UIScreen.main.bounds.height / 2) - 20 - sideButtons.frame.height), width: sideButtons.frame.width, height: sideButtons.frame.height)
        
        // Initialize a `FloatingPanelController` object.
        fpc = FloatingPanelController()
        
        // Assign self as the delegate of the controller.
        fpc.delegate = self
        
        fpc.surfaceView.backgroundColor = .clear
        
        // For any IOS version other than IOS10 round corners.
        if #available(iOS 11, *) {
            fpc.surfaceView.cornerRadius = 9.0
        } else {
            fpc.surfaceView.cornerRadius = 0.0
        }
        
        // Add shadow
        fpc.surfaceView.shadowHidden = false
        
        // Set a content view controller.
        let contentVC = storyboard?.instantiateViewController(identifier: "TimesPanel") as? TimesPanelViewController
        fpc.set(contentViewController: contentVC)
        
        // Add and show the views managed by the `FloatingPanelController` object to self.view.
        fpc.addPanel(toParent: self)
        
        // Set up search modal
        fpcSearch = FloatingPanelController()
        fpcSearch.delegate = self
        fpcSearch.surfaceView.backgroundColor = .clear
        fpcSearch.surfaceView.grabberHandle.isHidden = true
        fpcSearch.panGestureRecognizer.isEnabled = false
        let searchContentVC = storyboard?.instantiateViewController(identifier: "searchPanel") as? SearchPanelViewController
        searchContentVC?.mapView = mapView
        searchContentVC?.fpc = fpcSearch
        searchContentVC?.cellTapDelegate = self
        fpcSearch.set(contentViewController: searchContentVC)
        
        // Load annotations
        loadAnnotations()
        
    }
    
    @objc func mapViewLongPress(recogniser: UIGestureRecognizer) {
        if recogniser.state == UIGestureRecognizer.State.began {
            let touchPoint = recogniser.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            addAnnotation(item: MKMapItem(placemark: MKPlacemark(coordinate: newCoordinates)))
        }
    }
    
    func loadAnnotations() {
        let locationStore = LocationStore()
        print(locationStore.read())
        mapView.removeAnnotations(mapView.annotations)
        let search = BackendSearchLocations()
        for locationStruct in locationStore.read() {
            let newAnnotation = CustomAnnotationClass(id:locationStruct.id, title: search.parseAddress(selectedItem: locationStruct.location.placemark), coordinate: locationStruct.location.placemark.coordinate)
            mapView.addAnnotation(newAnnotation)
        }
    }
    
    // Actions
    @IBAction func handleSearchTap(recogniser:UITapGestureRecognizer) {
        // Show the user that the button has been tapped
        UIView.animate(withDuration: 0.1, animations: {
            () in
            self.searchIconView.backgroundColor = UIColor.lightGray
            self.searchIconView.alpha = 0.8
        }, completion: {
            (finished: Bool) in
            self.searchIconView.backgroundColor = UIColor.clear
            self.searchIconView.alpha = 1
        })
        
        self.present(fpcSearch, animated: true, completion: nil)
        
    }
    @IBAction func handleLocationTap(recogniser:UITapGestureRecognizer) {
        // Show the user that the button has been tapped
        UIView.animate(withDuration: 0.1, animations: {
            () in
            self.locationIconView.backgroundColor = UIColor.lightGray
            self.locationIconView.alpha = 0.8
        }, completion: {
            (finished: Bool) in
            self.locationIconView.backgroundColor = UIColor.clear
            self.locationIconView.alpha = 1
        })
        
        if !locationButtonPressedBefore {
            // Setup location manager
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            mapView.showsUserLocation = true
            
            locationButtonPressedBefore = true
        }
        
        locationManager.requestLocation()
        
    }
    
    // Floating Panel Delegate Methods
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        if vc.contentViewController?.className == "TimesPanelViewController" {
            return TimesPanelLayout()
        } else if vc.contentViewController?.className == "SearchPanelViewController" {
            return SearchPanelLayout()
        } else {
            return nil
        }
    }
    
    // CellTapDelegate Methods
    func cellTapped(matchingItem: MKMapItem) {
        addAnnotation(item: matchingItem)
        mapView.setCenter(matchingItem.placemark.coordinate, animated: true)
    }
    
    func addAnnotation(item: MKMapItem){
        
        let locationStore = LocationStore()
        
        if locationStore.read().count == 50 {
            // Tell user that he/she needs to remove an annotation to create another one.
        } else {
            let distanceApartOtherAnnotationsMustBe: Int = 2000
            
            var foundSimilar = false
            for locationStruct in locationStore.read() {
                if (item.placemark.location?.distance(from: locationStruct.location.placemark.location!))! < Double(distanceApartOtherAnnotationsMustBe + 1) {
                    print("too close")
                    mapView.setCenter(locationStruct.location.placemark.coordinate, animated: true)
                    foundSimilar = true
                }
            }
            
            if foundSimilar {
               return
            } else {
                
                let search = BackendSearchLocations()
                
                guard let id = locationStore.create(locationParam: item) else { return }
                
                let newAnnotation = CustomAnnotationClass(id:id, title: search.parseAddress(selectedItem: item.placemark), coordinate: item.placemark.coordinate)
                
                mapView.addAnnotation(newAnnotation)
                
            }
        }
        
    }
    
    // Map View Delegate Methods
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? CustomAnnotationClass else { return nil }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "AnnotationView")
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "AnnotationView")
        }
        
        let image = UIImage(systemName: String(annotation.id) + ".circle.fill")
        let size = CGSize(width: 50, height: 50)
        let renderer = UIGraphicsImageRenderer(size: size)
        annotationView?.image = renderer.image { (context) in
            image!.draw(in: CGRect(origin: .zero, size: size))
        }
        annotationView?.contentMode = .scaleAspectFit
        annotationView?.largeContentTitle = annotation.title
        annotationView?.backgroundColor = .white
        annotationView?.clipsToBounds = true
        annotationView?.layer.cornerRadius = 25
        
        annotationView?.canShowCallout = false
        
        return annotationView
        
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("the annotation was selected")
    }
    
    // CLLocationManagerDelegate Methods
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("location requested")
            
            let span = MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error)")
    }
    
    // UIGestureRecognizerDelegate methods
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

}

// MARK: CustomAnnotationClass
class CustomAnnotationClass: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    
    var id: Int
    
    var title: String?
    
    init(id: Int, title: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.title = title
        self.coordinate = coordinate
    }
}

// MARK: TimesPanelViewController
class TimesPanelViewController: UIViewController {
    
    // Outlets
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var topTitleView: UIView!
    
    // For iOS 10 only
    private lazy var shadowLayer: CAShapeLayer = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Programatically setup stuff in the top title section.
        // Subtitle
        let subtitle = UILabel()
        subtitle.frame = CGRect(x: 0, y: 0, width: 164, height: 18)
        subtitle.backgroundColor = .clear
        subtitle.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.39)
        
        subtitle.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.semibold)
        let subtitleParagraphStyle = NSMutableParagraphStyle()
        subtitleParagraphStyle.lineHeightMultiple = 1.16
        subtitle.attributedText = NSMutableAttributedString(string: "FROM YOUR SELECTIONS", attributes: [NSAttributedString.Key.kern: -0.08, NSAttributedString.Key.paragraphStyle: subtitleParagraphStyle])
        topTitleView.addSubview(subtitle)
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.widthAnchor.constraint(equalToConstant: 164).isActive = true
        subtitle.heightAnchor.constraint(equalToConstant: 18).isActive = true
        subtitle.leadingAnchor.constraint(equalTo: topTitleView.leadingAnchor, constant: 16).isActive = true
        subtitle.topAnchor.constraint(equalTo: topTitleView.topAnchor, constant: 25).isActive = true
        // Large Title
        let largeTitle = UILabel()
        largeTitle.frame = CGRect(x: 0, y: 0, width: 104, height: 41)
        largeTitle.backgroundColor = .clear
        largeTitle.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        largeTitle.font = UIFont.systemFont(ofSize: 34, weight: UIFont.Weight.bold)
        let largeTitleParagraphStyle = NSMutableParagraphStyle()
        largeTitleParagraphStyle.lineHeightMultiple = 1.01
        largeTitle.attributedText = NSMutableAttributedString(string: "Times", attributes: [NSAttributedString.Key.kern: 0.41, NSAttributedString.Key.paragraphStyle: largeTitleParagraphStyle])
        topTitleView.addSubview(largeTitle)
        largeTitle.translatesAutoresizingMaskIntoConstraints = false
        largeTitle.widthAnchor.constraint(equalToConstant: 104).isActive = true
        largeTitle.heightAnchor.constraint(equalToConstant: 41).isActive = true
        largeTitle.leadingAnchor.constraint(equalTo: topTitleView.leadingAnchor, constant: 16).isActive = true
        largeTitle.topAnchor.constraint(equalTo: topTitleView.topAnchor, constant: 46).isActive = true
        
    }
    
    override func viewDidLayoutSubviews() {
        
        if #available(iOS 11, *) {
        } else {
            // Add rounding corners on iOS 10
            visualEffectView.layer.cornerRadius = 9.0
            visualEffectView.clipsToBounds = true
    
            // Add shadow manually on iOS 10
            view.layer.insertSublayer(shadowLayer, at: 0)
            let rect = visualEffectView.frame
            let path = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: 9.0, height: 9.0))
            shadowLayer.frame = visualEffectView.frame
            shadowLayer.shadowPath = path.cgPath
            shadowLayer.shadowColor = UIColor.black.cgColor
            shadowLayer.shadowOffset = CGSize(width: 0.0, height: 1.0)
            shadowLayer.shadowOpacity = 0.2
            shadowLayer.shadowRadius = 3.0
        }
        
    }
    
}

// MARK: TimesPanelLayout
class TimesPanelLayout: FloatingPanelLayout {
    
    public var initialPosition: FloatingPanelPosition {
        return .tip
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        
        // Get safe area values
        var bottomSafeArea: CGFloat
        let window = UIApplication.shared.windows[0]

        if #available(iOS 11.0, *) {
            bottomSafeArea = window.safeAreaInsets.bottom
        } else {
            let safeFrame = window.safeAreaLayoutGuide.layoutFrame
            bottomSafeArea = window.frame.maxY - safeFrame.maxY
        }
        
        // Setup snapping points of pull up view.
        switch position {
        case .full: return 16.0 // A top inset from safe area
        case .half:
            return ( ( UIScreen.main.bounds.size.height / 2 ) - bottomSafeArea ) // A bottom inset from the safe area
        case .tip: return 96.0 // A bottom inset from the safe area
        case .hidden: return nil // Or `case .hidden: return nil`
        }
    }
    
}

// MARK: SearchViewController
class SearchPanelViewController: UIViewController, UITableViewDataSource, UISearchBarDelegate, UITableViewDelegate {
    
    // Passed through mapView
    var mapView: MKMapView? = nil
    var fpc: FloatingPanelController? = nil
    var search: BackendSearchLocations!
    
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var closeButton: UIImageView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    weak var cellTapDelegate: CellTapDelegate?
    
    let spacing: CGFloat = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        tableView.dataSource = self
        
        search = BackendSearchLocations()
        search.mapView = mapView
        
        if search.matchingItems.count == 0 {
            tableView.rowHeight = 353
        } else {
            tableView.rowHeight = 64 + spacing
        }
    }
    
    // Actions
    @IBAction func closeButtonAction(recogniser: UITapGestureRecognizer) {
        print("hi")
        UIView.animate(withDuration: 0.1, animations: {
            () in
            self.closeButton.alpha = 0.2
        }, completion: {
            (finished: Bool) in
            self.closeButton.alpha = 1
        })
        close()
    }
    
    // Table View Data Source and Delegate Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if search.matchingItems.count == 0 {
            return 1
        } else {
            return search.matchingItems.count // Number of rows basically
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        print("updating")
        
        if search.matchingItems.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NothingFoundTableViewCell", for: indexPath) as! NothingFoundTableViewCell
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CustomSearchTableViewCell", for: indexPath) as! CustomSearchTableViewCell
            print(indexPath.section)
            let item = search.matchingItems[indexPath.row]
            print(item)
            cell.title.text = "\(item.placemark.name ?? "") | \(item.placemark.country ?? "")"
            cell.subtitle.text = "\(item.placemark.thoroughfare ?? ""), \(item.placemark.locality ?? ""), \(item.placemark.subLocality ?? ""), \(item.placemark.administrativeArea ?? ""), \(item.placemark.postalCode ?? ""), \(item.placemark.country ?? "")"
            cell.bigRightLabel.text = item.timeZone?.abbreviation()
            
            return cell
        }
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Cell Tapped
        if !(self.search.matchingItems.count == 0) {
            if let cellTapDelegate = self.cellTapDelegate {
                cellTapDelegate.cellTapped(matchingItem: search.matchingItems[indexPath.row])
                close()
            }
        }
        
    }
    
    // Search Bar Delegate Method
    func searchBar(_: UISearchBar, textDidChange: String) {
        search.updateMatchingItems(text: textDidChange, completion: { () in
            if self.search.matchingItems.count == 0 {
                self.tableView.rowHeight = 353
            } else {
                self.tableView.rowHeight = 64 + self.spacing
            }
            
            self.tableView.reloadData()
        })
    }
    
    // Close
    private func close() {
        print("test")
        // Hide it
        self.dismiss(animated: true, completion: {
            () in
            print("dismissed")
        })
    }
    
}

//MARK: CellTapDelegate
protocol CellTapDelegate: AnyObject {
    func cellTapped(matchingItem: MKMapItem)
}

// MARK: CustomSearchTableViewCell
class CustomSearchTableViewCell: UITableViewCell {
    
    // Outlets
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var bigRightLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let spacing: CGFloat = 7.5

        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: spacing, left: 0, bottom: 0, right: 0))
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
    }
    
}

// MARK: SearchPanelLayout
class SearchPanelLayout: FloatingPanelLayout {
    
    public var initialPosition: FloatingPanelPosition {
        return .full
    }
    
    public var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .hidden]
    }
    
    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        
        // Get safe area values
        var topSafeArea: CGFloat
        let window = UIApplication.shared.windows[0]

        if #available(iOS 11.0, *) {
            topSafeArea = window.safeAreaInsets.top
        } else {
            let safeFrame = window.safeAreaLayoutGuide.layoutFrame
            topSafeArea = safeFrame.minY
        }
        
        switch position {
            case .full: return (0.0 - topSafeArea) // A top inset from safe area
            case .half: return 216.0 // A bottom inset from the safe area
            case .tip: return 44.0 // A bottom inset from the safe area
            default: return nil // Or `case .hidden: return nil`
        }
    }
    
}

// MARK: NothingFoundTableViewCell
class NothingFoundTableViewCell: UITableViewCell {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
    }
    
}

// To get name of class
extension UIViewController {
    var className: String {
        return NSStringFromClass(self.classForCoder).components(separatedBy: ".").last!
    }
}
