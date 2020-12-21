# HTMLBuilder

Swift library for generating HTML using  [Result Builder](https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md)

# Features

- Clean & clear syntax
- Composable & extensible
- Conditional and iteration support
- Underlying generation with libxml2 for always valid results
- Built-in convenient builders and modifiers for common cases
- Raw HTML integration

# Usage

## Tree builder

An HTML tree is built by combining `Node` which is a protocol implemented on `Element` and `String`

```swift
let tree = Element.html(head: {
    Element.metadata(charset: "UTF-8")
    Element(name: "title") { "Hello world" }
}, body: {
    Element.division {
        Element(name: "h1") { "Hello" }
        Element.paragraph { "Lorem ipsum dolor sit amet, <consectetur> adipiscing elit, sed & eiusmod." }
    }
})
print(tree.renderHTML())
```
Will output:
```html
<html><head><meta charset="UTF-8"><title>Hello world</title></head><body><div><h1>Hello</h1><p>Lorem ipsum dolor sit amet, &lt;consectetur&gt; adipiscing&nbsp;elit, sed &amp; eiusmod.</p></div></body></html>
```

## Condition and Iteration
Conditions (`if`, `if else`, `switch`) and iterations (`for ... in`) will work the same as imperative control-flow.

```swift
let cond1 = true
let cond2 = false
let elements = ["Lorem", "ipsum"]
let treeControlFlow = Element.html(head: {
    Element.metadata(charset: "UTF-8")
    Element(name: "title") { "Hello world" }
}, body: {
    Element.division {
        if cond1 {
            Element(name: "h1") { "Hello" }
        }
        if cond2 {
            Element(name: "h1") { "Hello" }
        } else {
            Element(name: "h1") { "world" }
        }
        ForEach(elements) { el in
            Element.paragraph { el }
        }
    }
})
print(treeControlFlow.renderHTML())
```
Will output:
```html
<html><head><meta charset="UTF-8"><title>Hello world</title></head><body><div><h1>Hello</h1><h1>world</h1><p>Lorem</p><p>ipsum</p></div></body></html>
```

## Modifiers

`Element` is modifiable while building the tree. 
There is 2 built in modifiers, `identifier` and `class`

```swift
let modifierTree = Element.division {
    Element.paragraph { "Hello world" }.identifier("title")
}.class("container")
print(modifierTree.renderHTML())
```

Will output:
```html
<div class="container"><p id="title">Hello world</p></div>
```

## Raw HTML
You can include raw html in the tree with `RawHTML` 
```swift
let rawHTMLTree = try Element.division {
    try RawHTML("""
        <h1>hello world</h1>
        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit</p>
        """)
}
```
Will output:
```html
<div><h1>hello world</h1><p>Lorem ipsum dolor sit amet, consectetur adipiscing elit</p></div>
```
