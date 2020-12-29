import XCTest
import HTMLBuilder

final class HTMLBuilderTests: XCTestCase {
    func testRendererMultiple() {
        let element = Element.division {
            Element(name: "in1")
            "hello"
            Element(name: "in2")
        }
        XCTAssertEqual(element.renderHTML(), "<div><in1></in1>hello<in2></in2></div>")
    }
    func testRendererSingle() {
        let element = Element.division {
            "hello"
        }
        XCTAssertEqual(element.renderHTML(), "<div>hello</div>")
    }
    func testIf() {
        let condition = true
        let element = Element.division {
            if condition {
                "hello"
            }
            if !condition {
                "world"
            }
        }
        XCTAssertEqual(element.renderHTML(), "<div>hello</div>")
    }
    func testIfElse() {
        let condition = true
        let element = Element.division {
            if condition {
                "hello"
            } else {
                "world"
            }
        }
        XCTAssertEqual(element.renderHTML(), "<div>hello</div>")
    }
    func testForEach() {
        let elements = ["hello", "world"]
        let element = Element.division {
            ForEach(elements) { value in
                Element.division { value }
            }
        }
        XCTAssertEqual(element.renderHTML(), "<div><div>hello</div><div>world</div></div>")
    }
    static let testURL = URL(string: "http://test.fr")!
    func testSingleTag() {
        let img = Element.image(Self.testURL)
        XCTAssertEqual(img.renderHTML(), "<img src=\"\(Self.testURL.absoluteString)\">")
    }
    func testClassModifier() {
        let div = Element.division {
        }.class("myClass")
        XCTAssertEqual(div.renderHTML(), "<div class=\"myClass\"></div>")
    }
    func testIdentifierModifier() {
        let div = Element.division {
        }.identifier("myId")
        XCTAssertEqual(div.renderHTML(), "<div id=\"myId\"></div>")
    }
    func testAttributesModifier() {
        let div = Element.division {
        }.attributes {
            $0[.relationship] = "hello"
            $0[.source] = "world"
        }
        XCTAssertEqual(div.renderHTML(), "<div rel=\"hello\" src=\"world\"></div>")
    }
    func testHTMLRendering() {
        let html = Element.html(head: {
            Element.cssLink(Self.testURL)
        }, body: {
            Element.division {
                Element.button("hello")
                "world"
                Element.button("hello")
            }
            Element.paragraph { "paragraph" }
        })
        let expected = """
        <html><head><link href="http://test.fr" rel="stylesheet" type="text/css"></head><body><div><button type="button">hello</button>world<button type="button">hello</button></div><p>paragraph</p></body></html>
        """
        XCTAssertEqual(html.renderHTML(), expected)
    }
    func testCharacterEscaping() {
        let element = Element.division {
            "hello < > &"
        }
        XCTAssertEqual(element.renderHTML(), "<div>hello &lt; &gt; &amp;</div>")
    }
    func testRawHTML() throws {
        let element = try Element.division {
            try RawHTML("<p>hello</p>")
        }
        XCTAssertEqual(element.renderHTML(), "<div><p>hello</p></div>")
    }
    func testRawHTMLMultiple() throws {
        let element = try Element.division {
            try RawHTML("<p>hello</p><img src=\"http://test.fr\"><figure></figure>")
        }
        XCTAssertEqual(element.renderHTML(), "<div><p>hello</p><img src=\"http://test.fr\"><figure></figure></div>")
    }
    func testRawHTMLWithError() throws {
        let rawHTML = """
        <figure class="kg-card kg-gallery-card kg-width-wide"><div class="kg-gallery-container"><div class="kg-gallery-row"><div class="kg-gallery-image"><img src="http://localhost:2368/content/images/2020/11/Simulator-Screen-Shot---iPad--7th-generation----2020-10-01-at-18.27.03.png" width="2000" height="1500" alt srcset="http://localhost:2368/content/images/size/w600/2020/11/Simulator-Screen-Shot---iPad--7th-generation----2020-10-01-at-18.27.03.png 600w, http://localhost:2368/content/images/size/w1000/2020/11/Simulator-Screen-Shot---iPad--7th-generation----2020-10-01-at-18.27.03.png 1000w, http://localhost:2368/content/images/size/w1600/2020/11/Simulator-Screen-Shot---iPad--7th-generation----2020-10-01-at-18.27.03.png 1600w, http://localhost:2368/content/images/2020/11/Simulator-Screen-Shot---iPad--7th-generation----2020-10-01-at-18.27.03.png 2160w" sizes="(min-width: 720px) 720px"></div><div class="kg-gallery-image"><img src="http://localhost:2368/content/images/2020/11/Simulator-Screen-Shot---iPad--8th-generation----2020-09-29-at-10.44.17.png" width="2000" height="1500" alt srcset="http://localhost:2368/content/images/size/w600/2020/11/Simulator-Screen-Shot---iPad--8th-generation----2020-09-29-at-10.44.17.png 600w, http://localhost:2368/content/images/size/w1000/2020/11/Simulator-Screen-Shot---iPad--8th-generation----2020-09-29-at-10.44.17.png 1000w, http://localhost:2368/content/images/size/w1600/2020/11/Simulator-Screen-Shot---iPad--8th-generation----2020-09-29-at-10.44.17.png 1600w, http://localhost:2368/content/images/2020/11/Simulator-Screen-Shot---iPad--8th-generation----2020-09-29-at-10.44.17.png 2160w" sizes="(min-width: 720px) 720px"></div><div class="kg-gallery-image"><img src="http://localhost:2368/content/images/2020/11/Simulator-Screen-Shot---iPad--8th-generation----2020-09-24-at-11.43.37.png" width="2000" height="1500" alt srcset="http://localhost:2368/content/images/size/w600/2020/11/Simulator-Screen-Shot---iPad--8th-generation----2020-09-24-at-11.43.37.png 600w, http://localhost:2368/content/images/size/w1000/2020/11/Simulator-Screen-Shot---iPad--8th-generation----2020-09-24-at-11.43.37.png 1000w, http://localhost:2368/content/images/size/w1600/2020/11/Simulator-Screen-Shot---iPad--8th-generation----2020-09-24-at-11.43.37.png 1600w, http://localhost:2368/content/images/2020/11/Simulator-Screen-Shot---iPad--8th-generation----2020-09-24-at-11.43.37.png 2160w" sizes="(min-width: 720px) 720px"></div></div></div></figure>
        """
        
        _ = try Element.division {
            try RawHTML(rawHTML)
        }
    }
    func testRawMultipleAttributes() throws {
        let raw = """
        <div a="1" b="2" c="3" d></div>
        """
        XCTAssertEqual(try RawHTML(raw).nodes[0].renderHTML(), raw)
    }
    func testMeta() throws {
        let charset = Element.metadata(charset: "UTF-8")
        XCTAssertEqual(charset.renderHTML(), "<meta charset=\"UTF-8\">")
        
        let name = Element.metadata(name: "keywords", content: "HTML, CSS, JavaScript")
        XCTAssertEqual(name.renderHTML(), "<meta content=\"HTML, CSS, JavaScript\" name=\"keywords\">")
        
        let httpEquiv = Element.metadata(httpEquivalent: "refresh", content: "30")
        XCTAssertEqual(httpEquiv.renderHTML(), "<meta content=\"30\" http-equiv=\"refresh\">")
    }
    func testEquatable() throws {
        let element1 = Element.html(head: {
            Element.cssLink(Self.testURL)
        }, body: {
            Element.division {
                Element.button("hello")
                "world"
                Element.button("hello")
            }
            Element.paragraph { "paragraph" }
        })
        let element2 = Element.html(head: {
            Element.cssLink(Self.testURL)
        }, body: {
            Element.division {
                Element.button("hello")
                "world"
                Element.button("hello")
            }
            Element.paragraph { "paragraph" }
        })
        
        XCTAssertTrue(element1.isEqual(to: element2))
        XCTAssertFalse(element1.isEqual(to: "hello"))
        XCTAssertFalse(element1.isEqual(to: Element.division(content: { "hello" })))
        XCTAssertFalse(element1.isEqual(to: nil))
        
    }
    func testDocExamples() throws {
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
        
        let rawHTMLTree = try Element.division {
            try RawHTML("""
                <h1>hello world</h1>
                <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit</p>
                """)
        }
        print(rawHTMLTree.renderHTML())
        
        let modifierTree = Element.division {
            Element.paragraph { "Hello world" }.identifier("title")
        }.class("container")
        print(modifierTree.renderHTML())
    }
    static var allTests = [
        ("testExample", testRendererMultiple),
        ("testRendererSingle", testRendererSingle),
        ("testIf", testIf),
        ("testIfElse", testIfElse),
        ("testSingleTag", testSingleTag),
        ("testClassModifier", testClassModifier),
        ("testIdentifierModifier", testIdentifierModifier),
        ("testAttributesModifier", testAttributesModifier),
        ("testHTMLRendering", testHTMLRendering),
        ("testCharacterEscaping", testCharacterEscaping),
        ("testRawHTML", testRawHTML),
    ]
}
