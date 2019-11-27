//
//  SearchPanelViewController.swift
//  TimeConverter
//
//  Created by Samit Shaikh on 27/11/19.
//  Copyright © 2019 Samit Shaikh. All rights reserved.
//

// Apple's Stuff
import UIKit
import MapKit
import CoreLocation
import Foundation
// Third party pods
import FloatingPanel // https://github.com/SCENEE/FloatingPanel
import SwiftLocation // https://github.com/malcommac/SwiftLocation
import SwiftyPickerPopover // https://github.com/hsylife/SwiftyPickerPopover

// MARK: SearchPanelViewController
class SearchPanelViewController: UIViewController {
    
    // Passed through mapView
    var fpc: FloatingPanelController? = nil
    
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
        Log("hi")
        UIView.animate(withDuration: 0.1, animations: {
            () in
            self.closeButton.alpha = 0.2
        }, completion: {
            (finished: Bool) in
            self.closeButton.alpha = 1
        })
        
        self.dismiss(animated: true)
    }
    
}

// MARK: UITableViewDataSource
// MARK: UITableViewDelegate
extension SearchPanelViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count // Number of rows basically
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if searchResults.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NothingFoundTableViewCell", for: indexPath) as! NothingFoundTableViewCell
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CustomSearchTableViewCell", for: indexPath) as! CustomSearchTableViewCell
            let completion = searchResults[indexPath.row]
            
            cell.title.text = completion.title
            cell.subtitle.text = completion.subtitle
            
            let searchRequest = MKLocalSearch.Request(completion: completion)
            let search = MKLocalSearch(request: searchRequest)
            search.start { (response, error) in
                if error == nil {
                    let item = response?.mapItems[0]
                    Log(item)
                    cell.bigRightLabel.text = item?.timeZone?.abbreviation()
                    cell.smallRightLabel.text = item?.timeZone?.identifier
                }
            }
            
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        if self.searchResults.count != 0 {
            if let cellTapDelegate = self.cellTapDelegate {
                Log("cell tapped 2")
                let searchRequest = MKLocalSearch.Request(completion: searchResults[indexPath.row])
                let search = MKLocalSearch(request: searchRequest)
                search.start { (response, error) in
                    if error == nil {
                        Log(response?.mapItems[0])
                        cellTapDelegate.cellTapped(matchingItem: (response?.mapItems[0])!)
                        self.dismiss(animated: true)
                    } else {
                        Log(error!)
                    }
                }
            }
        }
        
    }
}

// MARK: UISearchBarDelegate
extension SearchPanelViewController: UISearchBarDelegate {
    func searchBar(_: UISearchBar, textDidChange: String) {
        searchCompleter.queryFragment = searchBar.text!
    }
}

// MARK: MKLocalSearchCompleterDelegate
extension SearchPanelViewController: MKLocalSearchCompleterDelegate {
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
        Log("completer error:: \(error)")
    }
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
