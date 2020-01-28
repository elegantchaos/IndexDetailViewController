// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 28/01/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit

public class IndexDetailViewController: UIViewController {
    
    public var collapsed = false {
        willSet {
            if newValue != collapsed {
                print("changed collapsed")
                DispatchQueue.main.async {
                    if newValue {
                        self.transitionToCollapsed()
                    } else {
                        self.transitionFromCollapsed()
                    }
                }
            }
        }
    }
    
    public var direction = NSLayoutConstraint.Axis.horizontal {
        didSet {
            print("changed direction")
            stackView.axis = direction
        }
    }
    
    public var indexController: UIViewController!
    public var detailController: UIViewController!

    var detailNavigation: UINavigationController!
    var stackView: UIStackView!
    
    override public func viewDidLoad() {
        addChild(indexController)

        detailNavigation = UINavigationController(rootViewController: detailController)
        detailNavigation.view.backgroundColor = .red
        detailNavigation.delegate = self
        addChild(detailNavigation)

        stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        view = stackView
        
        indexController.title = "index"
        indexController.view.backgroundColor = .blue
        
        detailController.title = "detail root"
        detailController.view.backgroundColor = .green
        
        stackView.addArrangedSubview(indexController.view)
        addChild(indexController)

        stackView.addArrangedSubview(detailNavigation.view)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCollapsedForTraits()
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateCollapsedForTraits()
    }

    func updateCollapsedForTraits() {
        
            switch direction {
                case .vertical:
                    collapsed = traitCollection.verticalSizeClass == .compact

                case .horizontal:
                    collapsed = traitCollection.horizontalSizeClass == .compact
                
                default:
                    break
            }
    }
    
    func transitionToCollapsed() {
        print("becoming collapsed")
        
        stackView.removeArrangedSubview(indexController.view)
        indexController.removeFromParent()
        indexController.view.removeFromSuperview()

        print("detail vcs: \(detailNavigation.viewControllers.map { $0.title!})")
        var items = detailNavigation.viewControllers
        items.remove(at: 0)
        items.insert(indexController, at: 0)

        indexController.view.frame.size = detailNavigation.view.frame.size
        detailNavigation.setViewControllers(items, animated: false)
        detailController.view.removeFromSuperview()
        print("detail vcs: \(detailNavigation.viewControllers.map { $0.title!})")
    }
    
    func transitionFromCollapsed() {
        print("becoming uncollapsed")
        print("detail vcs: \(detailNavigation.viewControllers.map { $0.title!})")
        var items = detailNavigation.viewControllers
        items.remove(at: 0)
        items.insert(detailController, at: 0)
        detailNavigation.setViewControllers(items, animated: false)
        print("detail vcs: \(detailNavigation.viewControllers.map { $0.title!})")

        indexController.view.removeFromSuperview()
        indexController.removeFromParent()
        stackView.insertArrangedSubview(indexController.view, at: 0)
        addChild(indexController)
    }
    
    public func showDetail(_ viewController: UIViewController) {
        
    }
    
    public func pushDetail(_ viewController: UIViewController) {
        detailNavigation.pushViewController(viewController, animated: true)
    }
}

extension IndexDetailViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        print(viewController.title)
        print(viewController.view)
    }
}
