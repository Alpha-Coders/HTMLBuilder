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
    func testClass() {
        let div = Element.division {
        }.class("myClass")
        XCTAssertEqual(div.renderHTML(), "<div class=\"myClass\"></div>")
    }
    func testIdentifier() {
        let div = Element.division {
        }.identifier("myId")
        XCTAssertEqual(div.renderHTML(), "<div id=\"myId\"></div>")
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
        <html><head><link href="http://test.fr" ref="stylesheet" type="text/css"></head><body><div><button type="button">hello</button>world<button type="button">hello</button></div><p>paragraph</p></body></html>
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
    }

    static var allTests = [
        ("testExample", testRendererMultiple),
        ("testRendererSingle", testRendererSingle),
        ("testIf", testIf),
        ("testIfElse", testIfElse),
        ("testSingleTag", testSingleTag),
        ("testClass", testClass),
        ("testIdentifier", testIdentifier),
        ("testHTMLRendering", testHTMLRendering),
        ("testCharacterEscaping", testCharacterEscaping),
        ("testRawHTML", testRawHTML),
    ]
}
