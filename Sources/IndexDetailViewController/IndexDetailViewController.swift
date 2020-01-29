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
        let items = isCollapsed ? [detailRootController!, indexController!] : [detailRootController!]
        detailNavigation.setViewControllers(items, animated: false)
        detailNavigation.pushViewController(viewController, animated: isCollapsed)
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
        detailNavigation.delegate = self
        addChild(detailNavigation)

        stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        view = stackView
        
        stackView.addArrangedSubview(indexController.view)
        addChild(indexController)

        indexController.navigationItem.hidesBackButton = true
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

        let indexView = indexController.view!
        let detailView = detailNavigation.view!
        
        func hideIndexViewTemporarily() {
            // hide the index view or the navagation view
            // we animate this, so that the stack view transitions smoothly from two to one view
            if detailNavigation.viewControllers.count == 1 {
                detailView.isHidden = true
                detailNavigation.isNavigationBarHidden = true
            } else {
                indexView.isHidden = true
            }
        }

        func updateNavigation() {
            print("indexController parent is \(indexController.parent)")
            // remove index view from the stack
            print("indexController view superview is \(indexController.view.superview)")
            stackView.removeArrangedSubview(indexView)
            print("indexController view superview is \(indexController.view.superview)")
            indexController.removeFromParent()
            indexView.removeFromSuperview()
            print("indexController view superview is \(indexController.view.superview)")
            print("indexController parent is \(indexController.parent)")

            // insert the index view into the navigation stack
            var items = detailNavigation.viewControllers
            items.insert(indexController, at: 1)
            indexView.isHidden = false
            detailView.isHidden = false
            detailNavigation.setViewControllers(items, animated: false)
            DispatchQueue.main.async {
                print("indexController view superview is \(self.indexController.view.superview)")
                print("indexController parent is \(self.indexController.parent)")
//                indexView.frame = detailView.frame
//                indexView.setNeedsLayout()
//                indexView.setNeedsUpdateConstraints()
                print("indexView is \(indexView)")
                print(indexView.constraints)
            }
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
        
        print("indexController parent is \(indexController.parent)")

        // remove the index view from the navigation stack
        var items = detailNavigation.viewControllers
        items.remove(at: 1)
        detailNavigation.setViewControllers(items, animated: false)
        indexController.view.isHidden = true
        print("indexController view superview is \(indexController.view.superview)")
        indexController.view.removeFromSuperview()
        indexController.removeFromParent()
        stackView.insertArrangedSubview(indexController.view, at: 0)
        addChild(indexController)
        print("indexController parent is \(indexController.parent)")

        UIView.animate(withDuration: 0.5,
                       animations: {
                            self.indexController.view.isHidden = false
                            self.detailNavigation.isNavigationBarHidden = items.count == 1
                        },
                       completion: { finished in
                        if finished {
                            self.detailNavigation.isNavigationBarHidden = items.count == 1
                            self.logNavigationStack(label: "views in stack now:")
                        }
        })

    }
    
    func logNavigationStack(label: String) {
        indexDetailChannel.debug("\(label): \(detailNavigation.viewControllers.map { $0.title ?? String(describing: $0) })")
    }
}

// MARK: UINavigation Delegate

extension IndexDetailViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        indexDetailChannel.debug("showing \(viewController.title ?? String(describing: viewController))")
        detailNavigation.isNavigationBarHidden = (viewController === indexController) || (viewController === detailRootController)
    }
}
