// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 28/01/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import Logger
import LayoutExtensions

let indexDetailChannel = Channel("com.elegantchaos.IndexDetail")

public protocol IndexDetailViewControllerDelegate: AnyObject {
    func indexDetailViewController(_ indexDetailViewController: IndexDetailViewController, changedCollapsedStateTo state: Bool)
    func indexDetailViewController(_ indexDetailViewController: IndexDetailViewController, willShowView viewController: UIViewController, ofType: IndexDetailViewController.ViewType)
    func indexDetailViewController(_ indexDetailViewController: IndexDetailViewController, didShowView viewController: UIViewController, ofType: IndexDetailViewController.ViewType)
}

public extension IndexDetailViewControllerDelegate {
    func indexDetailViewController(_ indexDetailViewController: IndexDetailViewController, changedCollapsedStateTo state: Bool) { }
    func indexDetailViewController(_ indexDetailViewController: IndexDetailViewController, willShowView viewController: UIViewController, ofType: IndexDetailViewController.ViewType) { }
    func indexDetailViewController(_ indexDetailViewController: IndexDetailViewController, didShowView viewController: UIViewController, ofType: IndexDetailViewController.ViewType) { }
}

public class IndexDetailViewController: UIViewController {

    // MARK: Public Properties
    
    public weak var delegate: IndexDetailViewControllerDelegate?
    
    /// Indicates whether the view is in collapsed or normal state.
    /// In the collapsed state, the index becomes the root view of the navigation stack.
    /// In the normal state, it is a separate view to the left/top of the navigation stack.

    public var isCollapsed = false {
        willSet {
            if isSetup && (newValue != isCollapsed) {
                DispatchQueue.main.async {
                    self.updateSizeConstraintsForDetail()
                    if newValue {
                        self.transitionToCollapsed()
                    } else {
                        self.transitionFromCollapsed()
                    }
                    self.delegate?.indexDetailViewController(self, changedCollapsedStateTo: newValue)
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
            if isSetup {
                updateSizeConstraintsForDetail()
            }
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
    
    /// Fractional width/height to use for the detail panel
    public var detailSizeFraction: CGFloat = 0.66 {
        didSet {
            if isSetup {
                updateSizeConstraintsForDetail()
            }
        }
    }
    
    // MARK: Internal Properties
    
    fileprivate var isSetup = false
    fileprivate var detailNavigation: UINavigationController!
    fileprivate var stackView: UIStackView!
    fileprivate var indexWrapper: IndexWrapperViewController?
    fileprivate var sizeConstraint: NSLayoutConstraint?
    
    // MARK: Public API
    
    public func showDetail(_ viewController: UIViewController) {
        let items = isCollapsed ? [detailRootController!, indexWrapper!] : [detailRootController!]
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
        // our root view is a stack which will contain the other views
        stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.axis = .horizontal
        view = stackView

        // we never want to go back explicitly to the detail root
        // (the index should be above it in the stack, or visible in the other panel)
        detailRootController.navigationItem.setHidesBackButton(true, animated: false)
        
        // when the index is pushed onto the stack, we want it to appear to be the root
        // so we don't want to be able to go back from it to the actual detail root
        indexController.navigationItem.setHidesBackButton(true, animated: false)

        // we create and control the detail navigation controller
        detailNavigation = UINavigationController(rootViewController: detailRootController)
        detailNavigation.delegate = self
        addChild(detailNavigation)
        
        updateCollapsedStateForTraits()
        if isCollapsed {
            // if we're starting collapsed, the index goes onto the navigation stack
            let wrapper = makeWrapperForIndexController()
            detailNavigation.pushViewController(wrapper, animated: false)
            indexWrapper = wrapper
        } else {
            // if we're starting un-collapsed, the index goes into the root stack
            stackView.addArrangedSubview(indexController.view)
            addChild(indexController)
        }

        // the navigation view is always in the root stack
        stackView.addArrangedSubview(detailNavigation.view)
        updateSizeConstraintsForDetail()
        isSetup = true
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
    
    /// Container view used to wrap the index when it's in the navigation stack
    /// (this is primarily a workaround for problems with the layout of the index view)
    class IndexWrapperViewController: UIViewController {
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            indexDetailChannel.debug("index container appeared")
        }
    }
    
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
    
    func updateSizeConstraintsForDetail() {
        sizeConstraint?.isActive = false
        if !isCollapsed {
            switch direction{
                case .horizontal:
                    sizeConstraint = detailNavigation.view.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: detailSizeFraction)

                case .vertical:
                    sizeConstraint = detailNavigation.view.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: detailSizeFraction)

                default:
                    break
            }
            sizeConstraint?.isActive = true
        }
    }
    
    func transitionToCollapsed() {
        indexDetailChannel.debug("becoming collapsed")

        updateSizeConstraintsForDetail()
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
                let wrapper = makeWrapperForIndexController()
                var items = detailNavigation.viewControllers
                items.insert(wrapper, at: 1)
                indexWrapper = wrapper
                detailNavigation.setViewControllers(items, animated: false)
            }
            
            UIView.animate(withDuration: animationDuration, animations: { hideIndexViewTemporarily() }, completion: { _ in updateNavigation() })
        }
    }
    
    func makeWrapperForIndexController() -> IndexWrapperViewController {
        let indexView = indexController.view!
        let enclosing = IndexWrapperViewController()
        enclosing.addChild(indexController)
        enclosing.view.addSubview(indexView)
        indexView.stickTo(view:enclosing.view)
        return enclosing
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
                indexWrapper = nil
                
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
    public enum ViewType {
        case index
        case detail
        case detailRoot
    }

    fileprivate func viewType(of viewController: UIViewController) -> ViewType {
        if viewController === indexWrapper {
            return .index
        } else if viewController === detailRootController {
            return .detailRoot
        } else {
            return .detail
        }
    }
    
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        indexDetailChannel.debug("showing \(viewController.title ?? String(describing: viewController))")
        
        let type = viewType(of: viewController)
        detailNavigation.isNavigationBarHidden = type != .detail
        delegate?.indexDetailViewController(self, willShowView: viewController, ofType: type)
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        let type = viewType(of: viewController)
        delegate?.indexDetailViewController(self, didShowView: viewController, ofType: type)
    }
}
