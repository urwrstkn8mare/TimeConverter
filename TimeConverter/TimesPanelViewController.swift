//
//  TimesPanelViewController.swift
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


// MARK: TimesPanelViewController

class TimesPanelViewController: UIViewController {
    // Outlets
    @IBOutlet var visualEffectView: UIVisualEffectView!
    @IBOutlet var topTitleView: UIView!
    @IBOutlet var tableView: UITableView!

    // For iOS 10 only
    private lazy var shadowLayer: CAShapeLayer = CAShapeLayer()

    var removeAnnotationDelegate: RemoveAnnotationDelegate?
    var setMapCentreDelegate: SetMapCentreDelegate?
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapCell(_:)))
        tableView.addGestureRecognizer(tapGesture)
        //tapGesture.delegate = self

        if defaults.object(forKey: "universalTime") == nil {
            defaults.set(Date(), forKey: "universalTime")
        }

        Log(defaults.value(forKey: "universalTime")!)

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
        subtitle.widthAnchor.constraint(equalToConstant: 170).isActive = true
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

    @objc func tapCell(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizer.State.ended {
            let tapLocation = recognizer.location(in: tableView)
            if let indexPath = self.tableView.indexPathForRow(at: tapLocation) {
                Log("selected \(indexPath.row)")

                setMapCentreDelegate?.setMapCentre(coordinate: LocationStore().read(id: indexPath.row + 1)[0].location.placemark.coordinate)
            }
        }
    }

    @IBAction func trashButtonAction(_ sender: UIButton) {
        removeAnnotationDelegate?.removeAnnotation(id: sender.tag)
    }

    @IBAction func editButtonAction(_ sender: UIButton) {
        Log("editing not implemented yet")

        if UIDevice.current.userInterfaceIdiom == .pad {
            DatePickerPopover(title: "Change the timee")
                .setDateMode(UIDatePicker.Mode.dateAndTime)
                .setSize(width: 350)
                .setSelectedDate(defaults.value(forKey: "universalTime") as! Date)
                .setDoneButton(title: "Confirm", action: { _, selectedDate in
                    self.defaults.set(selectedDate, forKey: "universalTime")
                    self.tableView.reloadData()
                })
                .setCancelButton(action: { _, _ in
                    Log("cancel")
                })
                .setArrowColor(.white)
                .setTimeZone(LocationStore().read(id: sender.tag)[0].location.timeZone!)
                .appear(originView: sender, baseViewController: self)
        } else {
            // add to actionsheetview
            let alertController = UIAlertController(title: "Change the time", message: " ", preferredStyle: UIAlertController.Style.actionSheet)

            let datePicker = UIDatePicker(frame: CGRect(x: 0, y: 25, width: alertController.view.frame.width, height: 260))
            datePicker.datePickerMode = .dateAndTime
            datePicker.timeZone = LocationStore().read(id: sender.tag)[0].location.timeZone

            alertController.view.addSubview(datePicker) // add subview

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in

                Log("cancel action")
            }

            let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler: { _ in

                Log("confrim action \(datePicker.date)")
                self.defaults.set(datePicker.date, forKey: "universalTime")
                self.tableView.reloadData()

            })

            // add buttons to action sheet
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)

            let height: NSLayoutConstraint
            height = NSLayoutConstraint(item: alertController.view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 400)
            alertController.view.addConstraint(height)

            present(alertController, animated: true, completion: nil)
        }
    }
}

// MARK: UITableViewDelegate

// MARK: UITableViewDataSource

extension TimesPanelViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        // Get the locations from core data and return how many
        // there and gives it to the table view. The table view then creates that
        // many number of cells.
        return LocationStore().read().count
    }

    // This method is called for each cell.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // This initialises a cell from the storyboard.
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTimesTableViewCell") as! CustomTimesTableViewCell
        Log(indexPath.row)
        // This gets the corresponding item from core data.
        let item = LocationStore().read(id: indexPath.row + 1)[0]
        // This reads the universal time from the universal defaults (like
        // core data but simpler).
        let universalTime = defaults.value(forKey: "universalTime")! as! Date
        
        // Sets icons depending on the iOS version.
        if #available(iOS 13, *) {
            cell.editImageButton.imageView?.image = UIImage(systemName: "square.and.pencil")
            cell.trashImageButton.imageView?.image = UIImage(systemName: "trash")
            cell.mainImageView.image = UIImage(systemName: String(item.id) + ".circle.fill")
        } else {
            cell.editImageButton.imageView?.image = UIImage(named: "square.and.pencil-image")
            cell.trashImageButton.imageView?.image = UIImage(named: "trash-image")
            cell.mainImageView.image = UIImage(named: String(item.id) + ".circle.fill-image")
        }
        // Sets the region label to the identifier of the time zone uppercased.
        cell.regionLabel.text = item.location.timeZone?.identifier.uppercased()
        
        // Formats the time zone and puts it in each of the labels.
        let formatter = DateFormatter()
        formatter.timeZone = item.location.timeZone

        formatter.dateFormat = "h:mm"
        cell.timeLabel.text = formatter.string(from: universalTime)

        formatter.dateFormat = "a"
        cell.pmLabel.text = formatter.string(from: universalTime).uppercased()

        formatter.dateFormat = "EEEE, d MMM"
        cell.dateLabel.text = formatter.string(from: universalTime)

        // Gives the two buttons tags so they can be identified in their
        // corresponding IBActions.
        cell.trashImageButton.tag = item.id
        cell.editImageButton.tag = item.id

        return cell
    }
}

// MARK: CustomTimesTableViewCell

class CustomTimesTableViewCell: UITableViewCell {
    // Outlets
    @IBOutlet var mainImageView: UIImageView!
    @IBOutlet var regionLabel: UILabel!
    @IBOutlet var trashImageButton: UIButton!
    @IBOutlet var editImageButton: UIButton!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var pmLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
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
            // Fallback on earlier versions
            bottomSafeArea = window.layoutMargins.bottom
        }

        // Setup snapping points of pull up view.
        switch position {
        // A top inset from safe area
        case .full: return 16.0
        // A bottom inset from the safe area
        case .half: return ((UIScreen.main.bounds.size.height / 2) - bottomSafeArea)
        // A bottom inset from the safe area
        case .tip: return 96.0
        // Or `case .hidden: return nil`
        case .hidden: return nil
        }
    }
}

// MARK: TimesPanelLandscapeLayout

class TimesPanelLandscapeLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .full
    }

    public var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .tip]
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0
        case .tip: return 96.0
        default: return nil
        }
    }

    public func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        let leftAnchorConstraint: NSLayoutConstraint
        if #available(iOS 11.0, *) {
            leftAnchorConstraint = surfaceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8.0)
        } else {
            // Fallback on earlier versions
            leftAnchorConstraint = surfaceView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8.0)
        }
        
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad ? true : false
        let bounds = UIScreen.main.bounds
        var width: CGFloat?

        if isIpad {
            width = 414
        } else {
            width = bounds.width
        }
        
        return [
            leftAnchorConstraint, surfaceView.widthAnchor.constraint(equalToConstant: width!),
        ]
    }

    public func backdropAlphaFor(position _: FloatingPanelPosition) -> CGFloat {
        return 0.0
    }
}
