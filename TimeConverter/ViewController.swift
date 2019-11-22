//
//  ViewController.swift
//  TimeConverter
//
//  Created by Samit Shaikh on 3/11/19.
//  Copyright © 2019 Samit Shaikh. All rights reserved.
//

// TODO: Do the actual time conversion stuff and stuff.
// TODO: Store universal time persitently via core data.

import UIKit
import MapKit
import FloatingPanel // https://github.com/SCENEE/FloatingPanel
import MapKit
import CoreLocation
import Foundation

// MARK: ViewController
class ViewController: UIViewController, FloatingPanelControllerDelegate, CellTapDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {

    // Outlets
    @IBOutlet weak var sideButtons: UIVisualEffectView!
    @IBOutlet weak var searchIconView: UIView!
    @IBOutlet weak var locationIconView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchIconImageView: UIImageView!
    @IBOutlet weak var locationIconImageView: UIImageView!
    
    var fpc: FloatingPanelController!
    var fpcSearch: FloatingPanelController!
    var fpcSearchShownBefore: Bool = false
    var locationButtonPressedBefore: Bool = false
    var locationManager: CLLocationManager!
    var contentVC: TimesPanelViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if #available(iOS 13, *) {
            searchIconImageView.image = UIImage(systemName: "magnifyingglass")
            locationIconImageView.image = UIImage(systemName: "location")
        } else {
            searchIconImageView.image = UIImage(named: "magnifyingglass-image")
            locationIconImageView.image = UIImage(named: "location-image")
        }
        
        // Prevents showing user location by default.
        mapView.showsUserLocation = false
        
        // Accessing Map View Delegate
        mapView.delegate = self
        
        // Set up long press
        let longPressGestureRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(mapViewLongPress(recogniser:)))
        longPressGestureRecogniser.minimumPressDuration = 0.25
        mapView.addGestureRecognizer(longPressGestureRecogniser)
        
        // Set up side buttons on the map
        sideButtons.layer.cornerRadius = 10.0
        sideButtons.clipsToBounds = true
        sideButtons.layer.borderWidth = 1
        if #available(iOS 13, *) {
            sideButtons.layer.borderColor = UIColor.opaqueSeparator.cgColor
        } else {
            sideButtons.layer.borderColor = UIColor(red: 198.0/255.0, green: 198.0/255.0, blue: 200.0/255.0, alpha: 1.0).cgColor
        }
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
        if #available(iOS 13.0, *) {
            contentVC = (storyboard?.instantiateViewController(identifier: "TimesPanel") as? TimesPanelViewController)!
        } else {
            // Fallback on earlier versions
            contentVC = (storyboard?.instantiateViewController(withIdentifier: "TimesPanel") as? TimesPanelViewController)!
        }
        fpc.set(contentViewController: contentVC)
        
        // Add and show the views managed by the `FloatingPanelController` object to self.view.
        fpc.addPanel(toParent: self)
        
        // Set up search modal
        fpcSearch = FloatingPanelController()
        fpcSearch.delegate = self
        fpcSearch.surfaceView.backgroundColor = .clear
        fpcSearch.surfaceView.grabberHandle.isHidden = true
        fpcSearch.panGestureRecognizer.isEnabled = false
        fpcSearch.isRemovalInteractionEnabled = true
        var searchContentVC: SearchPanelViewController
        if #available(iOS 13.0, *) {
            searchContentVC = (storyboard?.instantiateViewController(identifier: "searchPanel") as? SearchPanelViewController)!
        } else {
            // Fallback on earlier versions
            searchContentVC = (storyboard?.instantiateViewController(withIdentifier: "searchPanel") as? SearchPanelViewController)!
        }
        searchContentVC.fpc = fpcSearch
        searchContentVC.cellTapDelegate = self
        fpcSearch.set(contentViewController: searchContentVC)
        
        // Load annotations
        loadAnnotations()
        
    }
    
    @objc func mapViewLongPress(recogniser: UIGestureRecognizer) {
        if recogniser.state == UIGestureRecognizer.State.began {
            let touchPoint = recogniser.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            print("detected")
            
            let newId = addAnnotation(item: MKMapItem(placemark: MKPlacemark(coordinate: newCoordinates)))
            if newId != nil {
                CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude).geocode(completion: { (placemark, error) in
                    if let error = error as? CLError {
                        print("CLError:", error)
                        return
                    } else if let placemark = placemark?.first {
                        print(placemark)
                        let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                        print("updating")
                        LocationStore().update(id: newId!, newLocation: mapItem, newId: nil)
                        self.contentVC?.tableView.reloadData()
                        
                    }
                })
            }
            
        }
    }
    
    func loadAnnotations() {
        let locationStore = LocationStore()
        mapView.removeAnnotations(mapView.annotations)
        for locationStruct in locationStore.read() {
            let newAnnotation = CustomAnnotationClass(id:locationStruct.id, coordinate: locationStruct.location.placemark.coordinate)
            self.mapView.addAnnotation(newAnnotation)
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
        if addAnnotation(item: matchingItem) != nil {
            mapView.setCenter(matchingItem.placemark.coordinate, animated: true)
            self.contentVC?.tableView.reloadData()
        }
    }
    
    func addAnnotation(item: MKMapItem) -> Int? {
        
        let locationStore = LocationStore()
        
        let maxCount: Int
        if #available(iOS 13, *) {
            maxCount = 50
        } else {
            maxCount = 10
        }
        
        let result = locationStore.read()
        if result.count == maxCount {
            let alert = UIAlertController(title: "Too many locations!", message: "You can only create a maximum of \(maxCount) locations.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return nil
        } else {
            let distanceApartOtherAnnotationsMustBe: Int = 900000
                
            let newId = locationStore.create(locationParam: item)
            
            let newAnnotation = CustomAnnotationClass(id: newId!, coordinate: item.placemark.coordinate)
            
            self.mapView.addAnnotation(newAnnotation)
            
            for locationStruct in result {
                if (item.placemark.location?.distance(from: locationStruct.location.placemark.location!))! < Double(distanceApartOtherAnnotationsMustBe + 1) {
                    print("too close")
                    
                    self.mapView.setCenter(locationStruct.location.placemark.coordinate, animated: true)
                    self.mapView.removeAnnotation(newAnnotation)
                    locationStore.delete(id: newId!)
                    
                    let alert = UIAlertController(title: "Too many close!", message: "Your location must be at least \(distanceApartOtherAnnotationsMustBe/1000)km away from any other location.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                    
                    return nil
                }
            }
            
            return newId
        }
        
    }
    
    func removeAnnotation(id: Int) {
        let locationStore = LocationStore()
        locationStore.delete(id: id)
        for item in locationStore.read() {
            if item.id > id {
                locationStore.update(id: item.id, newLocation: nil, newId: item.id - 1)
            }
        }
        loadAnnotations()
    }
    
    // Map View Delegate Methods
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? CustomAnnotationClass else { return nil }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "AnnotationView")
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "AnnotationView")
        }
        
        var image: UIImage
        if #available(iOS 13.0, *) {
            image = UIImage(systemName: String(annotation.id) + ".circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .medium))!
        } else {
            // Fallback on earlier versions
            image = UIImage(named: String(annotation.id) + ".circle.fill-image")!
        }
        let size = CGSize(width: 50, height: 50)
        let renderer = UIGraphicsImageRenderer(size: size)
        annotationView?.image = renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        annotationView?.contentMode = .scaleAspectFit
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
        // this function is delayed for some reason
        print("location requested")
        if let location = locations.first {
            print("location requested 2")
            
            let span = MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            print("locaiton requested 3")
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
    
    init(id: Int, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.coordinate = coordinate
    }
}

// MARK: TimesPanelViewController
class TimesPanelViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UniversalTimeDelegate {
    
    // Outlets
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var topTitleView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    // For iOS 10 only
    private lazy var shadowLayer: CAShapeLayer = CAShapeLayer()
    
    var universalTime: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        universalTime = Date()
        
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
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 9.0, height: 9.0))
            shadowLayer.frame = visualEffectView.frame
            shadowLayer.shadowPath = path.cgPath
            shadowLayer.shadowColor = UIColor.black.cgColor
            shadowLayer.shadowOffset = CGSize(width: 0.0, height: 1.0)
            shadowLayer.shadowOpacity = 0.2
            if #available(iOS 11.0, *) {
                shadowLayer.shadowRadius = 3.0
            }
        }
        
    }
    
    // MARK: todo below
    // TODO: Do stuff here
    @IBAction func trashButtonAction(_ sender: UIButton) {
        let cell = sender.superview as! CustomTimesTableViewCell
        let indexPath = tableView.indexPath(for: cell)
        
        
    }
    @IBAction func editButtonAction(_ sender: UIButton) {
        let cell = sender.superview as! CustomTimesTableViewCell
        let indexPath = tableView.indexPath(for: cell)
        
        
    }
    
    // Table View Delegate and Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return LocationStore().read().count
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTimesTableViewCell") as! CustomTimesTableViewCell
        cell.delegate = self
        let item = LocationStore().read()[indexPath.row]
        
        if #available(iOS 13, *) {
            cell.editImageButton.imageView?.image = UIImage(systemName: "square.and.pencil")
            cell.trashImageButton.imageView?.image = UIImage(systemName: "trash")
            cell.mainImageView.image = UIImage(systemName: String(item.id) + ".circle.fill")
        } else {
            cell.editImageButton.imageView?.image = UIImage(named: "square.and.pencil-image")
            cell.trashImageButton.imageView?.image = UIImage(named: "trash-image")
            cell.mainImageView.image = UIImage(named: String(item.id) + ".circle.fill-image")
        }
        cell.regionLabel.text = item.location.timeZone?.identifier.uppercased()
        
        let formatter = DateFormatter()
        formatter.timeZone = item.location.timeZone
        
        formatter.dateFormat = "h:mm"
        cell.timeLabel.titleLabel?.text = formatter.string(from: universalTime!)
        
        formatter.dateFormat = "a"
        cell.pmLabel.text = formatter.string(from: universalTime!).uppercased()
        
        formatter.dateFormat = "EEEE, d MMM"
        cell.dateLabel.text = formatter.string(from: universalTime!)
        
        return cell
    }
    // when table view cell is selectedy
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        
    }
    
    // Universal Time Delegate Methods
    func set(time: Date) {
        universalTime = time
    }
    func get() -> Date {
        return universalTime!
    }
    
}

// MARK: CustomTimesTableViewCell
class CustomTimesTableViewCell: UITableViewCell {
    
    // Outlets
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var regionLabel: UILabel!
    @IBOutlet weak var trashImageButton: UIButton!
    @IBOutlet weak var editImageButton: UIButton!
    @IBOutlet weak var timeLabel: UIButton!
    @IBOutlet weak var pmLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    var delegate: UniversalTimeDelegate?
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    
}

protocol UniversalTimeDelegate {
    func set(time: Date)
    func get() -> Date
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
            // Fallback on earlier versions
            bottomSafeArea = window.layoutMargins.bottom
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
class SearchPanelViewController: UIViewController, UITableViewDataSource, UISearchBarDelegate, UITableViewDelegate, MKLocalSearchCompleterDelegate {
    
    // Passed through mapView
    //var mapView: MKMapView? = nil
    var fpc: FloatingPanelController? = nil
    //var search: BackendSearchLocations!
    
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var closeButton: UIImageView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet var closeButtonTapRecogniser: UITapGestureRecognizer!
    
    weak var cellTapDelegate: CellTapDelegate?
    
    let spacing: CGFloat = 5
    
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13, *) {
            closeButton.image = UIImage(systemName: "xmark.circle.fill")
        } else {
            closeButton.image = UIImage(named: "xmark.circle.fill-image")
        }
        
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        
        closeButtonTapRecogniser.cancelsTouchesInView = false
        tableView.allowsSelection = true
        
        searchCompleter.delegate = self
        
        if searchResults.count == 0 {
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
        if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count // Number of rows basically
        }
    }
    
    // This function was adapted from: https://github.com/gm6379/MapKitAutocomplete
    /**
      Highlights the matching search strings with the results
      - parameter text: The text to highlight
      - parameter ranges: The ranges where the text should be highlighted
      - parameter size: The size the text should be set at
      - parameter semiBold: The bool that decides if the text is semi bold
      - returns: A highlighted attributed string with the ranges highlighted.
     */
    private func highlightedText(_ text: String, inRanges ranges: [NSValue], size: CGFloat, semiBold: Bool = false) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text)
        var regular = UIFont.systemFont(ofSize: size)
        if semiBold {
            regular = UIFont.systemFont(ofSize: size, weight: UIFont.Weight.semibold)
        }
        attributedText.addAttribute(NSAttributedString.Key.font, value:regular, range:NSMakeRange(0, text.count))

        let bold = UIFont.boldSystemFont(ofSize: size)
        for value in ranges {
            attributedText.addAttribute(NSAttributedString.Key.font, value:bold, range:value.rangeValue)
        }
        return attributedText
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if searchResults.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NothingFoundTableViewCell", for: indexPath) as! NothingFoundTableViewCell
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CustomSearchTableViewCell", for: indexPath) as! CustomSearchTableViewCell
            let completion = searchResults[indexPath.row]
            cell.title.attributedText = highlightedText(completion.title, inRanges: completion.titleHighlightRanges, size: 20.0, semiBold: true)
            cell.subtitle.attributedText = highlightedText(completion.subtitle, inRanges: completion.subtitleHighlightRanges, size: 14.0)
            
            let searchRequest = MKLocalSearch.Request(completion: completion)
            let search = MKLocalSearch(request: searchRequest)
            search.start { (response, error) in
                if error == nil {
                    let item = response?.mapItems[0]
                    cell.bigRightLabel.text = item?.timeZone?.abbreviation()
                    cell.smallRightLabel.text = item?.timeZone?.identifier
                }
            }
            
            return cell
        }
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Cell Tapped
        print("cell tapped")
        
        UIView.animate(withDuration: 0.1, animations: { () in
            tableView.cellForRow(at: indexPath)?.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
        }, completion: { (finished) in
            tableView.cellForRow(at: indexPath)?.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1)
        })
        
        tableView.deselectRow(at: indexPath, animated: false)
    
        if self.searchResults.count != 0 {
            if let cellTapDelegate = self.cellTapDelegate {
                print("cell tapped 2")
                let searchRequest = MKLocalSearch.Request(completion: searchResults[indexPath.row])
                let search = MKLocalSearch(request: searchRequest)
                search.start { (response, error) in
                    if error == nil {
                        cellTapDelegate.cellTapped(matchingItem: (response?.mapItems[0])!)
                        self.close()
                    } else {
                        print(error ?? "no error?")
                    }
                }
            }
        }
        
    }
    
    // Search Bar Delegate Method
    func searchBar(_: UISearchBar, textDidChange: String) {
        searchCompleter.queryFragment = searchBar.text!
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
    
    // Local Search Completer Delegate
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        
        if searchResults.count == 0 {
            tableView.rowHeight = 353
        } else {
            tableView.rowHeight = 64 + spacing
        }
        
        tableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("completer error:: \(error)")
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
    @IBOutlet weak var smallRightLabel: UILabel!
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        let spacing: CGFloat = 7.5
        
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: spacing, left: 0, bottom: 0, right: 0))
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        
    }
    
//    override func setSelected(_ selected: Bool, animated: Bool) {
//
//        if selected {
//            contentView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
//            print("cool")
//        } else {
//            contentView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1)
//        }
//
//    }
    
}

// MARK: SearchPanelLayout
class SearchPanelLayout: FloatingPanelLayout {
    
    public var initialPosition: FloatingPanelPosition {
        return .full
    }
    
    public var supportedPositions: Set<FloatingPanelPosition> {
        //return [.full, .hidden]
        return [.full]
    }
    
    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        
        // Get safe area values
        var topSafeArea: CGFloat
        let window = UIApplication.shared.windows[0]

        if #available(iOS 11.0, *) {
            topSafeArea = window.safeAreaInsets.top
        } else {
            topSafeArea = window.layoutMargins.top
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
    
    @IBOutlet weak var nothingFoundImageView: UIImageView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        
        if #available(iOS 13, *) {
            nothingFoundImageView.image = UIImage(systemName: "text.badge.xmark")
        } else {
            nothingFoundImageView.image = UIImage(named: "text.badge.xmark-image")
        }
        
    }
    
}

// 16.0
//
