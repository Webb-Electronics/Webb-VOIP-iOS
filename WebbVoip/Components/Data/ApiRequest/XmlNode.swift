import Foundation

/// The XML Wrapper to Create a Object from a XML String, the main parent node tagname will always be XMLDocument
/// each XML Node contains: tag name, text, and attributes (dict)
///     [Parent Node]
///            [Current Node]
///                 [Child Node]
///                 [Child Node]
///                 [Child Node]
///            [Next Node]
///                 ...
class XmlNode {
    private(set) var parentNode: XmlNode?
    private(set) var childNodes: [XmlNode] = []
    private(set) var tagName: String = "XMLDocument"
    fileprivate(set) var text: String = ""
    fileprivate(set) var attributes: [String: String] = [:]

    private init(_ parent: XmlNode? = nil, tagName: String) {
        self.parentNode = parent
        self.tagName = tagName
    }

    /// initlize the object from Data
    /// - Parameter fromData: Data object that contains the XML String
    public init(fromData: Data) throws {
        let parser = XMLParser(data: fromData)
        let delegate = XmlParserDelegate(self)
        parser.delegate = delegate
        if !parser.parse() {
            throw GeneralError.runtimeError("Not able to parse the XML")
        }
    }

    fileprivate func push(_ elementName: String) -> XmlNode {
        let childElement = XmlNode(self, tagName: elementName)
        childNodes.append(childElement)
        return childElement
    }

    fileprivate func pop() -> XmlNode? {
        parentNode
    }
}

private class XmlParserDelegate: NSObject, XMLParserDelegate {
    private var currentElement: XmlNode?

    fileprivate init(_ element: XmlNode) {
        self.currentElement = element
    }

    public func parser(_: XMLParser, didEndElement _: String, namespaceURI _: String?, qualifiedName _: String?) {
        currentElement = currentElement?.pop()
    }

    public func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = currentElement?.push(elementName)
        currentElement?.attributes = attributeDict
    }

    func parser(_: XMLParser, foundCharacters string: String) {
        currentElement?.text += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
