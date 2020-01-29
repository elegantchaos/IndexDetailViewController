// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 28/01/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import Logger
import ViewExtensions

let indexDetailChannel = Channel("com.elegantchaos.IndexDetail")

public class IndexDetailViewController: UIViewController {
    
    // MARK: Public Properties
    
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
    
    /// Indicates the direction of the split.
    /// A horizontal split puts the index on the left (for left-to-right systems).
    /// A vertical split puts the index omn the top (for top-to-bottom systems).
    public var direction = NSLayoutConstraint.Axis.horizontal {
        didSet {
            indexDetailChannel.debug("changed direction to \(direction)")
            stackView.axis = direction
        }
    }
    
    /// A controller to use for the index view.
    /// Needs to be set by the time viewDidLoad is called on this controller.
    public var indexController: UIViewController!
    
    /// A controller to use for the root of the navigation stack.
    /// Needs to be set by the time viewDidLoad is called on this controller.
    public var detailRootController: UIViewController!

    // MARK: Internal Properties
    
    fileprivate var detailNavigation: UINavigationController!
    fileprivate var stackView: UIStackView!
    
    
    // MARK: Public API
    
    public func showDetail(_ viewController: UIViewController) {
        detailNavigation.popToRootViewController(animated: false)
        detailNavigation.pushViewController(viewController, animated: false)
    }
    
    public func pushDetail(_ viewController: UIViewController) {
        detailNavigation.pushViewController(viewController, animated: true)
    }
}

// MARK: View Overrides

public extension IndexDetailViewController {
    override func viewDidLoad() {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCollapsedStateForTraits()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateCollapsedStateForTraits()
    }
}

// MARK: Internal Methods

fileprivate extension IndexDetailViewController {
    
    func updateCollapsedStateForTraits() {
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
        logNavigationStack(label: "views in stack were:")

        // remove index view from the stack
        
        func hideIndexViewTemporarily() {
            if detailNavigation.viewControllers.count == 1 {
                detailNavigation.view.isHidden = true
            } else {
                indexController.view.isHidden = true
            }
        }

        func updateNavigation() {
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
            indexController.view.isHidden = false
            detailNavigation.setViewControllers(items, animated: false)
            detailNavigation.view.isHidden = false
            self.logNavigationStack(label: "views in stack now:")
        }
        
        UIView.animate(withDuration: 0.5,
                       animations: {
                        hideIndexViewTemporarily()
                        },
                       completion: { finished in
                        if finished {
                            updateNavigation()
                        }
        })
            

    }
    
    func transitionFromCollapsed() {
        indexDetailChannel.debug("becoming uncollapsed")
        logNavigationStack(label: "views in stack were:")
        
        func addIndexViewToStack() {
            indexController.view.removeFromSuperview()
            indexController.removeFromParent()
            stackView.insertArrangedSubview(indexController.view, at: 0)
            addChild(indexController)
            logNavigationStack(label: "views in stack now:")
        }
        
        var items = detailNavigation.viewControllers
        items.remove(at: 0)
        items.insert(detailRootController, at: 0)
        detailNavigation.setViewControllers(items, animated: true) {
            addIndexViewToStack()
        }
    }
    
    func logNavigationStack(label: String) {
        indexDetailChannel.debug("\(label): \(detailNavigation.viewControllers.map { $0.title ?? String(describing: $0) })")
    }
}

// MARK: UINavigation Delegate

extension IndexDetailViewController: UINavigationControllerDelegate {
    
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        indexDetailChannel.debug("showing \(viewController.title ?? String(describing: viewController))")
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        print("did show")
    }
}
