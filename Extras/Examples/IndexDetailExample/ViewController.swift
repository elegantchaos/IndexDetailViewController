// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/01/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import IndexDetailViewController

class ViewController: UIViewController {
    var indexDetailViewController: IndexDetailViewController!
    @IBOutlet weak var contentStack: UIStackView!
    @IBOutlet weak var toggleCollapsedButton: UIButton!
    @IBOutlet weak var toggleDirectionButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        indexDetailViewController = IndexDetailViewController()
        addChild(indexDetailViewController)
        
        let indexView = storyboard?.instantiateViewController(identifier: "Index") as! ExampleIndexViewController
        indexView.indexDetailViewController = indexDetailViewController
        indexDetailViewController.indexController = indexView

        let detailRootView = storyboard?.instantiateViewController(identifier: "Root") as! ExampleDetailRootViewController
        indexDetailViewController.detailRootController = detailRootView

        contentStack.insertArrangedSubview(indexDetailViewController.view, at: 2)
        updateToggleCollapsedIcon()
        updateToggleDirectionIcon()
    }
    
    func updateToggleCollapsedIcon() {
        let name: String
        if indexDetailViewController.direction == .vertical {
            name = indexDetailViewController.isCollapsed ? "arrow.down.square" : "arrow.up.square"
        } else {
            name = indexDetailViewController.isCollapsed ? "arrow.right.square" : "arrow.left.square"
        }
        
        toggleCollapsedButton.setImage(UIImage(systemName: name), for: .normal)
    }

    func updateToggleDirectionIcon() {
        let name = indexDetailViewController.direction == .vertical ? "square.split.1x2" : "square.split.2x1"
        toggleDirectionButton.setImage(UIImage(systemName: name), for: .normal)
    }
    
    @IBAction func toggleCollapsed(_ sender: Any) {
        indexDetailViewController.isCollapsed = !indexDetailViewController.isCollapsed
        updateToggleCollapsedIcon()
    }
    
    @IBAction func toggleDirection(_ sender: Any) {
        indexDetailViewController.direction = indexDetailViewController.direction == .horizontal ? .vertical : .horizontal
        updateToggleDirectionIcon()
        updateToggleCollapsedIcon()
    }
}

class ExampleIndexViewController: UITableViewController {
    var indexDetailViewController: IndexDetailViewController!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print(view.frame)
        print(view.bounds)
    }
    
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = "Item \(indexPath.row)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

class ExampleDetailRootViewController: UIViewController {
    
}
