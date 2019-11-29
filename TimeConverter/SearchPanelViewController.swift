//
//  SearchPanelViewController.swift
//  TimeConverter
//
//  Created by Samit Shaikh on 27/11/19.
//  Copyright © 2019 Samit Shaikh. All rights reserved.
//

import UIKit
import CoreLocation
import FloatingPanel // https://github.com/SCENEE/FloatingPanel
import Foundation
import MapKit
import SwiftLocation // https://github.com/malcommac/SwiftLocation
import SwiftyPickerPopover // https://github.com/urwrstkn8mare/SwiftyPickerPopover

// MARK: SearchPanelViewController

class SearchPanelViewController: UIViewController {
    // Passed down through ViewController
    var fpc: FloatingPanelController?

    // Outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet var closeButton: UIImageView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var closeButtonTapRecogniser: UITapGestureRecognizer!

    // Set by ViewController
    weak var cellTapDelegate: CellTapDelegate?

    // Define the spacing between the cells.
    let spacing: CGFloat = 5

    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the close button image with SFSymbols or a bitmap (png) depending on
        // the iOS version.
        if #available(iOS 13, *) {
            closeButton.image = UIImage(systemName: "xmark.circle.fill")
        } else {
            closeButton.image = UIImage(named: "xmark.circle.fill-image")
        }

        // Set delegates and datasources
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        searchCompleter.delegate = self

        closeButtonTapRecogniser.cancelsTouchesInView = false
        
        // Allows cells in table view to be selected.
        tableView.allowsSelection = true

        // Sets the height depending on how many items in the search results there
        // are. If there is none it is bigger for the results not found cell.
        if searchResults.count == 0 {
            tableView.rowHeight = 353
        } else {
            tableView.rowHeight = 64 + spacing
        }
    }

    // Actions
    @IBAction func closeButtonAction(recogniser _: UITapGestureRecognizer) {
        Log("hi")
        
        // Animate the opacity of the close button going from 60% to 20% then back
        // to 60%.
        UIView.animate(withDuration: 0.1, animations: {
            () in
            self.closeButton.alpha = 0.2
        }, completion: {
            (_: Bool) in
            self.closeButton.alpha = 1
        })

        // Dismiss the search panel (this panel).
        dismiss(animated: true)
    }
}

// MARK: UITableViewDataSource

// MARK: UITableViewDelegate

extension SearchPanelViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        if searchResults.count == 0 {
            // If there is no search results have one row for the no-results cell.
            return 1
        } else {
            // If there are some search results than have the number of search
            // results cells.
            return searchResults.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchResults.count == 0 {
            // If there is no search results use the following cell. This cell
            // tells the user that no search results were found.
            let cell = tableView.dequeueReusableCell(withIdentifier: "NothingFoundTableViewCell", for: indexPath) as! NothingFoundTableViewCell

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CustomSearchTableViewCell", for: indexPath) as! CustomSearchTableViewCell
            
            // Get the completion from the search results based on what row the cell
            // is on.
            let completion = searchResults[indexPath.row]

            // Set title label text to the completion's title and the subititle's
            // label text to the completion's subtitle.
            cell.title.text = completion.title
            cell.subtitle.text = completion.subtitle

            // Make a search request for the map item data with the completion.
            let searchRequest = MKLocalSearch.Request(completion: completion)
            let search = MKLocalSearch(request: searchRequest)
            search.start { response, error in
                if error == nil {
                    // Get the first item out of the results if there is no erros.
                    let item = response?.mapItems[0]
                    
                    Log(item)
                    
                    // Set the big right label's text to the abbreviation of the
                    // location's timezone.
                    cell.bigRightLabel.text = item?.timeZone?.abbreviation()
                    // Set the small right label's text to the identifier of the
                    // location's timezone.
                    cell.smallRightLabel.text = item?.timeZone?.identifier
                }
            }

            return cell
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchResults.count != 0 {
            if let cellTapDelegate = self.cellTapDelegate {
                Log("cell tapped 2")
                
                // Make the same map item search request as above.
                let searchRequest = MKLocalSearch.Request(completion: searchResults[indexPath.row])
                let search = MKLocalSearch(request: searchRequest)
                search.start { response, error in
                    if error == nil {
                        Log(response?.mapItems[0])
                        
                        // If there was no error, than call the cellTapped() method
                        // defined in the cellTapDelegate with the first result
                        // of the request.
                        cellTapDelegate.cellTapped(matchingItem: (response?.mapItems[0])!)
                        
                        // Dismiss the search panel.
                        self.dismiss(animated: true)
                    } else {
                        Log(error!)
                        
                        // Create and presnet an alert to tell the user that there
                        // was a problem most likely caused by no connection.
                        let alert = UIAlertController(title: "There was a problem.", message: "Something happened and we couldn't get the required data for that search result. This was most likely a problem with your connection. Please try again later.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        alert.present(alert, animated: true, completion: nil)
                        
                    }
                }
            }
        }
    }
}

// MARK: UISearchBarDelegate

extension SearchPanelViewController: UISearchBarDelegate {
    // This method is run everytime the text in the search bar changes in any way.
    func searchBar(_: UISearchBar, textDidChange _: String) {
        // Set the query text for the search completer to the search bar's text.
        searchCompleter.queryFragment = searchBar.text!
    }
}

// MARK: MKLocalSearchCompleterDelegate

extension SearchPanelViewController: MKLocalSearchCompleterDelegate {
    // This method is run when the completer updates its results.
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results

        // If there is no results than set the row height to accomadte the not-found
        // cell otherwise normal height with spacing.
        if searchResults.count == 0 {
            tableView.rowHeight = 353
        } else {
            tableView.rowHeight = 64 + spacing
        }

        // Reload the tableview.
        tableView.reloadData()
    }

    func completer(_: MKLocalSearchCompleter, didFailWithError error: Error) {
        Log("completer error:: \(error)")
    }
}

// MARK: CustomSearchTableViewCell

class CustomSearchTableViewCell: UITableViewCell {
    // Outlets
    @IBOutlet var title: UILabel!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var bigRightLabel: UILabel!
    @IBOutlet var smallRightLabel: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()

        // Configure the search panel's table view's cell.
        let spacing: CGFloat = 7.5
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: spacing, left: 0, bottom: 0, right: 0))
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
    }
}

// MARK: SearchPanelLayout

class SearchPanelLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        // Make the initial position of the search panel the full positon.
        return .full
    }

    public var supportedPositions: Set<FloatingPanelPosition> {
        // Make the only supported positon of the search panel the full position.
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
        // Make the full position take up the entire height of the screen.
        case .full: return (0.0 - topSafeArea)
        
        // The rest doesn't really matter.
        case .half: return 216.0
        case .tip: return 44.0
        default: return nil
        }
    }
}

// MARK: NothingFoundTableViewCell

class NothingFoundTableViewCell: UITableViewCell {
    @IBOutlet var nothingFoundImageView: UIImageView!

    override func layoutSubviews() {
        super.layoutSubviews()

        // Set the corner radius of the nothing found table view cell.
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true

        // Set the nothign found image to a SF Symbol or a bitmap (png) version of
        // that for iOS 12 or under.
        if #available(iOS 13, *) {
            nothingFoundImageView.image = UIImage(systemName: "text.badge.xmark")
        } else {
            nothingFoundImageView.image = UIImage(named: "text.badge.xmark-image")
        }
    }
}
