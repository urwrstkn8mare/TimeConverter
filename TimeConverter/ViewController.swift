//
//  ViewController.swift
//  TimeConverter
//
//  Created by Samit Shaikh on 3/11/19.
//  Copyright © 2019 Samit Shaikh. All rights reserved.
//

import UIKit
import MapKit
import FloatingPanel // https://github.com/SCENEE/FloatingPanel

// MARK: ViewController
class ViewController: UIViewController, FloatingPanelControllerDelegate {

    // Outlets
    @IBOutlet weak var sideButtons: UIVisualEffectView!
    @IBOutlet weak var searchIconView: UIView!
    @IBOutlet weak var locationIconView: UIView!
    
    var fpc: FloatingPanelController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
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
        
    }
    
    // Actions
    @IBAction func handleSearchTap(recogniser:UITapGestureRecognizer) {
        // Show the user that the button has been tapped
        UIView.animate(withDuration: 0.1, animations: {
            () in
            self.searchIconView.backgroundColor = UIColor.lightGray
        }, completion: {
            (finished: Bool) in
            self.searchIconView.backgroundColor = UIColor.clear
        })
    }
    @IBAction func handleLocationTap(recogniser:UITapGestureRecognizer) {
        // Show the user that the button has been tapped
        UIView.animate(withDuration: 0.1, animations: {
            () in
            self.locationIconView.backgroundColor = UIColor.lightGray
        }, completion: {
            (finished: Bool) in
            self.locationIconView.backgroundColor = UIColor.clear
        })
    }
    
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return TimesPanelLayout()
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
        default: return nil // Or `case .hidden: return nil`
        }
    }
    
}

