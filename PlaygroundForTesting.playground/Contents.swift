#if swift(>=5.2)
print("Hello, Swift 5.2")

#elseif swift(>=5.1)
print("Hello, Swift 5.1")

#elseif swift(>=5.0)
print("Hello, Swift 5.0")

#elseif swift(>=4.2)
print("Hello, Swift 4.2")

#elseif swift(>=4.1)
print("Hello, Swift 4.1")

#elseif swift(>=4.0)
print("Hello, Swift 4.0")

#elseif swift(>=3.2)
print("Hello, Swift 3.2")

#elseif swift(>=3.0)
print("Hello, Swift 3.0")

#elseif swift(>=2.2)
print("Hello, Swift 2.2")

#elseif swift(>=2.1)
print("Hello, Swift 2.1")

#elseif swift(>=2.0)
print("Hello, Swift 2.0")

#elseif swift(>=1.2)
print("Hello, Swift 1.2")

#elseif swift(>=1.1)
print("Hello, Swift 1.1")

#elseif swift(>=1.0)
print("Hello, Swift 1.0")

#endif

import MapKit
let mapItem: Data

do {
    mapItem = try NSKeyedArchiver.archivedData(withRootObject: MKMapItem.forCurrentLocation(), requiringSecureCoding: false)
} catch {
    print("failed")
    mapItem = Data()
}

do {
    let decodedMapItem = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(mapItem) as? MKMapItem
    print(decodedMapItem)
} catch {
    print("error")
}

//: A UIKit based Playground for presenting user interface
 
import UIKit
import PlaygroundSupport

class MyViewController : UIViewController {
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        let label = UILabel()
        label.frame = CGRect(x: 150, y: 200, width: 200, height: 20)
        label.text = "Hello World!"
        label.textColor = .black
        
        view.addSubview(label)
        self.view = view
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
