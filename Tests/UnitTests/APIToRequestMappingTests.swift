import TestsCommon
@testable import WebDriver
import XCTest

let base64TestImage: String =
    "iVBORw0KGgoAAAANSUhEUgAAAAgAAAAHCAYAAAA1WQxeAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAACXBIWXMAAB2GAAAdhgFdohOBAAAABmJLR0QA/wD/AP+gvaeTAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIzLTA3LTEzVDIwOjAxOjQ1KzAwOjAwCWqxhgAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMy0wNy0xM1QyMDowMTo0NSswMDowMHg3CToAAAC2SURBVBhXY/iPDG7c+///5y8oBwJQFRj4/P9f3QNhn78Appi+fP3LkNfxnIFh43oGBiE+BoYjZxkYHj5iYFi2goHhzVsGpoePfjBMrrzLUNT4jIEh2IaBQZCTgaF1EgODkiIDg4gwA9iKpILL/xnkL/xnkLzyv8UUaIVL2P//Xz5DrGAAgoPzVjDosRxmaG4UZxArjAAa/YGBYfdxkBTEhP37bv9/+eIDWAcYHDsHNOEbkPH/PwCcrZANcnx9SAAAAABJRU5ErkJggg=="

/// Tests how usage of high-level Session/Element APIs map to lower-level requests
class APIToRequestMappingTests: XCTestCase {
    func testSessionAndElement() throws {
        let mockWebDriver = MockWebDriver()
        let session = Session(in: mockWebDriver, id: "mySession")
        XCTAssertEqual(session.id, "mySession")

        // Session requests unit-tests
        mockWebDriver.expect(path: "session/mySession/title", method: .get) { WebDriverResponse(value: "mySession.title") }
        XCTAssertEqual(session.title, "mySession.title")

        mockWebDriver.expect(path: "session/mySession/screenshot", method: .get) { WebDriverResponse(value: base64TestImage) }
        let data: Data = session.makePNGScreenshot()
        XCTAssert(isPNG(data: data))

        mockWebDriver.expect(path: "session/mySession/element", method: .post, type: Session.ElementRequest.self) {
            XCTAssertEqual($0.using, "name")
            XCTAssertEqual($0.value, "myElement.name")
            return WebDriverResponse(value: .init(ELEMENT: "myElement"))
        }
        let element = session.findElement(byName: "myElement.name")!

        mockWebDriver.expect(path: "session/mySession/element/active", method: .post, type: Session.ActiveElementRequest.self) {
            WebDriverResponse(value: .init(ELEMENT: "myElement"))
        }
        _ = session.activeElement!

        mockWebDriver.expect(path: "session/mySession/moveto", method: .post, type: Session.MoveToRequest.self) {
            XCTAssertEqual($0.elementId, "myElement")
            XCTAssertEqual($0.xOffset, 30)
            XCTAssertEqual($0.yOffset, 0)
            return WebDriverResponse<CodableNone>()
        }
        session.moveTo(element: element, xOffset: 30, yOffset: 0)

        mockWebDriver.expect(path: "session/mySession/click", method: .post, type: Session.ButtonRequest.self) {
            XCTAssertEqual($0.button, .left)
            return WebDriverResponse<CodableNone>()
        }
        session.click(button: .left)

        mockWebDriver.expect(path: "session/mySession/buttondown", method: .post, type: Session.ButtonRequest.self) {
            XCTAssertEqual($0.button, .right)
            return WebDriverResponse<CodableNone>()
        }
        session.buttonDown(button: .right)

        mockWebDriver.expect(path: "session/mySession/buttonup", method: .post, type: Session.ButtonRequest.self) {
            XCTAssertEqual($0.button, .right)
            return WebDriverResponse<CodableNone>()
        }
        session.buttonUp(button: .right)

        // Element requests unit-tests

        mockWebDriver.expect(path: "session/mySession/element/myElement/text", method: .get) { WebDriverResponse(value: "myElement.text") }
        XCTAssertEqual(element.text, "myElement.text")

        mockWebDriver.expect(path: "session/mySession/element/myElement/attribute/myAttribute.name", method: .get) { WebDriverResponse(value: "myAttribute.value") }
        XCTAssertEqual(element.getAttribute(name: "myAttribute.name"), "myAttribute.value")

        mockWebDriver.expect(path: "session/mySession/element/myElement/click", method: .post)
        element.click()

        mockWebDriver
            .expect(path: "session/mySession/element/myElement/location", method: .get, type: Element.LocationRequest.self) { WebDriverResponse(value: .init(x: 10, y: -20)) }
        XCTAssert(element.location == (x: 10, y: -20))

        mockWebDriver
            .expect(path: "session/mySession/element/myElement/size", method: .get, type: Element.SizeRequest.self) { WebDriverResponse(value: .init(width: 100, height: 200)) }
        XCTAssert(element.size == (width: 100, height: 200))

        mockWebDriver.expect(path: "session/mySession/element/myElement/value", method: .post, type: Element.KeysRequest.self) {
            XCTAssertEqual($0.value, ["a", "b", "c"])
            return WebDriverResponse<CodableNone>()
        }
        element.sendKeys(value: ["a", "b", "c"])

        // Account for session deinitializer
        mockWebDriver.expect(path: "session/mySession", method: .delete)
    }
}
