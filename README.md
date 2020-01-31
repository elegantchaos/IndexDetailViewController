# IndexDetailViewController

Somehow, the behaviour of `UISplitViewController` always ends up confusing me, and never seems to be what I want.

So I found myself wondering how hard it would be to implement something from scratch, which is less complicated, and just works out of the box.

This is that thing...

## Design

The basic design is for a two-panel view, in a master-detail style, where one panel can be hidden in a compact environment. 

I've used the term "index" in preference to "master", as that's the purpose it always serves in my use-cases (ymmv).

### Panels

The left/top panel is an index. A controller to determine the contents of this panel is supplied by the user. 

The right/bottom panel is a navigation stack. The navigation controller is created automatically, and generally doesn't need external intervention. A controller to determine the contents of the root of this stack is supplied by the user. Other controllers are pushed onto the stack, either by the index, or by other code.

### Orientation

The panels can be configured in either left-right or top-bottom orientation. 

This is mostly a consequence of the implementation, which uses a `UIStackView` internally, making it easy to switch axis. Whether the vertical configuration proves to be useful remains to be seen.

### Collapsing Behaviour

The view is collapsed automatically when the traits environment becomes compact on the relevant axis.

It can also be collapsed manually by setting a property.

When collapsed, the index panel is automatically moved onto the navigation stack. 

If nothing else was showing on the stack when it was collapsed, it's the index you'll see by default.

If something was already on the stack when it was collapsed, then that's what you'll still see, but you will be able to pop it off and return to the index with the "back" button.

### Configuration

When configuring the view, the client supplies two view controllers: the index controller, and the detail root controller.

The detail root controller supplies a view to show when the detail panel is visible but nothing has been pushed onto it. Typically this might say something like "nothing selected", or show some other placeholder UI.

The index controller is responsible for supplying the view for the index panel. Typically the user interacts with this view to set/change/push items into the detail view. 

The current detail view is changed with `showDetail`. This is equivalent to clearing the navigation stack then pushing the supplied view controller. It would typically be done in response to the user choosing an item from the index.

Additional items can be add onto the detail stack with `pushDetail`. This is equivalent to pushing the supplied view controller. It would typically be done in response to the user tapping something on the currently showing detail view.   

### Appearance

The controller adds no chrome of its own.

In particular, no visual divider is added between the two panels. 

For now, if you want a divider, you can include it as part of the view managed by the index controller, and make that controller hide it when the overall controller is in collapsed mode.

I may add the option to have the controller itself manage a divider view, but I was aiming for the simplest implementation possible.
