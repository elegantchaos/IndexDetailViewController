// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 28/01/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import Logger
import LayoutExtensions

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

    /// Duration to use for the collapse/un-collapse animation.
    public var animationDuration = 0.6
    
    // MARK: Internal Properties
    
    fileprivate var detailNavigation: UINavigationController!
    fileprivate var stackView: UIStackView!
    fileprivate var indexContainer: UIViewController?
        
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
                if traitCollection.verticalSizeClass == .compact {
                    isCollapsed = true
            }
            
            case .horizontal:
                if traitCollection.horizontalSizeClass == .compact {
                    isCollapsed = true
            }
            
            default:
                break
        }
    }
    
    func transitionToCollapsed() {
        indexDetailChannel.debug("becoming collapsed")

        if let indexView = indexController.view, let detailView = detailNavigation.view {
            
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
                detailView.isHidden = false
                
                // remove index view from the stack
                stackView.removeArrangedSubview(indexView)
                indexController.removeFromParent()
                indexView.removeFromSuperview()
                indexView.isHidden = false
                
                // insert the index view into the navigation stack
                let enclosing = UIViewController()
                enclosing.addChild(indexController)
                enclosing.view.addSubview(indexView)
                indexView.stickTo(view:enclosing.view)
                var items = detailNavigation.viewControllers
                items.insert(enclosing, at: 1)
                indexContainer = enclosing
                detailNavigation.setViewControllers(items, animated: false)
            }
            
            UIView.animate(withDuration: animationDuration, animations: { hideIndexViewTemporarily() }, completion: { _ in updateNavigation() })
        }
    }
    
    func transitionFromCollapsed() {
        indexDetailChannel.debug("becoming uncollapsed")
        
        if let indexView = indexController.view, let detailView = detailNavigation.view {
            var items = detailNavigation.viewControllers

            func updateRootStack() {
                // remove the index view from the navigation stack
                items.remove(at: 1)
                indexView.removeFromSuperview()
                indexController.removeFromParent()
                stackView.insertArrangedSubview(indexView, at: 0)
                addChild(indexController)
                indexContainer = nil
                
                // start with either the index or the navigation view hidden
                // we will animate one of them back to visibility, to generate a slide animation in the right direction
                detailNavigation.setViewControllers(items, animated: false)
                if items.count == 1 {
                    detailView.isHidden = true
                } else {
                    indexView.isHidden = true
                }
            }

            func reshowViews() {
                // show whichever view was hidden, so that it animates into place
                indexView.isHidden = false
                detailView.isHidden = false
                detailNavigation.isNavigationBarHidden = items.count == 1
            }

            updateRootStack()
            UIView.animate(withDuration: animationDuration, animations: { reshowViews() })
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
        
        let showingIndex = viewController === indexContainer
        let showingRoot = viewController === detailRootController
        detailNavigation.isNavigationBarHidden = showingIndex || showingRoot
    }
}
