// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/01/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import IndexDetailViewController

class ViewController: UIViewController {
    var indexDetailViewController: IndexDetailViewController!
    @IBOutlet weak var contentStack: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        indexDetailViewController = IndexDetailViewController()
        addChild(indexDetailViewController)
        
        let indexView = storyboard?.instantiateViewController(identifier: "Index") as! ExampleIndexViewController
        indexView.indexDetailViewController = indexDetailViewController
        indexDetailViewController.indexController = indexView

        let detailLabel = UILabel()
        detailLabel.text = "detail root"
        let detailView = UIViewController()
        detailView.view = detailLabel
        detailView.title = "detail root"
        indexDetailViewController.detailRootController = detailView

        contentStack.insertArrangedSubview(indexDetailViewController.view, at: 2)
    }
    
    @IBAction func toggleCollapsed(_ sender: Any) {
        indexDetailViewController.isCollapsed = !indexDetailViewController.isCollapsed
    }
    
    @IBAction func toggleDirection(_ sender: Any) {
        indexDetailViewController.direction = indexDetailViewController.direction == .horizontal ? .vertical : .horizontal
    }
}

class ExampleIndexViewController: UIViewController {
    var indexDetailViewController: IndexDetailViewController!
    
    @IBAction func addDetail(_ sender: Any) {
        let detailView = storyboard?.instantiateViewController(identifier: "Detail") as! ExampleDetailViewController
        detailView.indexDetailViewController = indexDetailViewController
        indexDetailViewController.pushDetail(detailView)
    }
    
    @IBAction func showDetail(_ sender: Any) {
        let detailView = storyboard?.instantiateViewController(identifier: "Detail") as! ExampleDetailViewController
        detailView.indexDetailViewController = indexDetailViewController
        indexDetailViewController.showDetail(detailView)

    }
}

class ExampleDetailViewController: UIViewController {
    var indexDetailViewController: IndexDetailViewController!

    @IBAction func pushDetail(_ sender: Any) {
        let detailView = storyboard?.instantiateViewController(identifier: "Detail") as! ExampleDetailViewController
        detailView.indexDetailViewController = indexDetailViewController
        indexDetailViewController.pushDetail(detailView)
    }
}
