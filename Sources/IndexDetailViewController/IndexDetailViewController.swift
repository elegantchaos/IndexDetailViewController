// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 28/01/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import Logger

let indexDetailChannel = Channel("com.elegantchaos.IndexDetail")

public class IndexDetailViewController: UIViewController {
    
    /// Indicates whether the view is in collapsed or normal state.
    /// In the collapsed state, the index becomes the root view of the navigation stack.
    /// In the normal state, it is a separate view to the left/top of the navigation stack.

    public var isCollapsed = false {
        willSet {
            if newValue != isCollapsed {
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
            indexDetailChannel.debug("changed direction to \(direction)")
            stackView.axis = direction
        }
    }
    
    public var indexController: UIViewController!
    public var detailRootController: UIViewController!

    internal var detailNavigation: UINavigationController!
    internal var stackView: UIStackView!
    
    override public func viewDidLoad() {
        addChild(indexController)

        detailNavigation = UINavigationController(rootViewController: detailRootController)
        detailNavigation.view.backgroundColor = .red
        detailNavigation.delegate = self
        addChild(detailNavigation)

        stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        view = stackView
        
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
                    isCollapsed = traitCollection.verticalSizeClass == .compact

                case .horizontal:
                    isCollapsed = traitCollection.horizontalSizeClass == .compact
                
                default:
                    break
            }
    }
    
    func transitionToCollapsed() {
        indexDetailChannel.debug("becoming collapsed")
        logStack(label: "views in stack were:")

        // remove index view from the stack
        stackView.removeArrangedSubview(indexController.view)
        indexController.removeFromParent()
        indexController.view.removeFromSuperview()

        // remove detail root from the navigation stack
        var items = detailNavigation.viewControllers
        assert(items[0] === detailRootController)
        items.remove(at: 0)
        detailRootController.view.removeFromSuperview()

        // and replace it with the index
        items.insert(indexController, at: 0)
        indexController.view.frame.size = detailNavigation.view.frame.size
        
        detailNavigation.setViewControllers(items, animated: false)
        logStack(label: "views in stack now:")
    }
    
    func transitionFromCollapsed() {
        indexDetailChannel.debug("becoming uncollapsed")
        logStack(label: "views in stack were:")
        
        var items = detailNavigation.viewControllers
        items.remove(at: 0)
        items.insert(detailRootController, at: 0)
        detailNavigation.setViewControllers(items, animated: false)

        indexController.view.removeFromSuperview()
        indexController.removeFromParent()
        stackView.insertArrangedSubview(indexController.view, at: 0)
        addChild(indexController)
        logStack(label: "views in stack now:")
    }
    
    func logStack(label: String) {
        indexDetailChannel.debug("\(label): \(detailNavigation.viewControllers.map { $0.title ?? String(describing: $0) })")
    }
    
    public func showDetail(_ viewController: UIViewController) {
        detailNavigation.popToRootViewController(animated: false)
        detailNavigation.pushViewController(viewController, animated: false)
    }
    
    public func pushDetail(_ viewController: UIViewController) {
        detailNavigation.pushViewController(viewController, animated: true)
    }
}

extension IndexDetailViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        indexDetailChannel.debug("showing \(viewController.title ?? String(describing: viewController))")
    }
}
