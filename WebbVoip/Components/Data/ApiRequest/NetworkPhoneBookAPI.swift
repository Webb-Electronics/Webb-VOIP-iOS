import Foundation

/// request the phone book and return the name and the list of contacts
class NetworkPhoneBookAPI {
    /// Retrieve data from URL
    /// - Parameter url: string of the URL
    /// - Returns: (Name of the phone book, List of Contacts)
    static func retrieveData(url: String) async throws -> (String, [Contact]) {
        try await NetworkPhoneBookRequest(url: url).readXmlData()
    }

    private init() {}
}

private class NetworkPhoneBookRequest: NetworkRequest {
    let sendingHeaders: [String: String] = ["User-Agent": "fanvil yealink grandstream vpbxCommunicator"]

    var url: URL

    init(url: String) throws {
        guard let urlData = URL(string: url) else {
            throw GeneralError.runtimeError("URL Provided not valid")
        }
        self.url = urlData
    }
}

private extension NetworkPhoneBookRequest {
    func readXmlData() async throws -> (String, [Contact]) {
        let SUPPORTED_XML_FORMAT: [String: (XmlNode) throws -> (String, [Contact])] = [
            "FanvilIPPhoneDirectory": readGeneralXml,
            "YealinkIPPhoneDirectory": readGeneralXml,
            "AddressBook": readGrandstreamXml,
            "VCommunicatorPhoneDirectory": readGeneralXml,
        ]

        let data = try await sendRequest()
        let xmlNode = try XmlNode(fromData: data)
        guard xmlNode.tagName == "XMLDocument", let contentNode = xmlNode.childNodes.first else {
            throw GeneralError.runtimeError("Invalid Node received")
        }
        guard let readXmlFunc = SUPPORTED_XML_FORMAT[contentNode.tagName] else {
            throw GeneralError.runtimeError("Tag name not supproted")
        }
        return try readXmlFunc(contentNode)
    }

    ///  this supports: Fanvil, Yealink, and VitalPBX format,
    /// structure of the XML:
    ///  {DEFINED DOC TYPE}
    ///     {Title}
    ///     {Contact or DirectoryEntry}
    ///         {Name}
    ///         {Telephone}
    ///  ...
    /// - Parameter node: pass in the XmlNode
    /// - Returns: document name (String), list of contact obj
    private func readGeneralXml(_ node: XmlNode) throws -> (String, [Contact]) {
        var name = ""
        var contacts: [Contact] = []
        for ele in node.childNodes {
            switch ele.tagName {
            case "Title":
                name = ele.text
                continue
            case "DirectoryEntry", "Contact":
                var targets: [String] = []
                var username: String = ""
                for subele in ele.childNodes {
                    switch subele.tagName {
                    case "Name":
                        username = subele.text
                    case "Telephone":
                        targets.append(subele.text)
                    default:
                        print("unrecongnized data", subele.tagName, subele.text)
                        continue
                    }
                }
                if !username.isEmpty || !targets.isEmpty {
                    contacts.append(Contact(name: username, dialTarget: targets))
                }
                continue
            default:
                print("ignoring, continue", ele.tagName)
                continue
            }
        }
        return (name, contacts)
    }

    /// Please refer to https://www.grandstream.com/hubfs/Product_Documentation/gxp_wp_xml_phonebook.pdf?hsLang=en
    /// - Parameter node: xml node
    /// - Returns: document name (always empty), list if contact obj
    private func readGrandstreamXml(_ node: XmlNode) throws -> (String, [Contact]) {
        let name = ""
        var contacts: [Contact] = []

        for ele in node.childNodes {
            switch ele.tagName {
            case "Contact":
                var username = "Unknown Name"
                var targets: [String] = []
                for subele in ele.childNodes {
                    switch subele.tagName {
                    case "FirstName":
                        username = subele.text
                    case "Phone":
                        if
                            let number = subele.childNodes.first(where: { subelec in
                                subelec.tagName == "phonenumber"
                            })
                        {
                            if !number.text.isEmpty {
                                targets.append(number.text)
                            }
                        }
                    default:
                        print("ignoring", subele.tagName)
                    }
                }
                if !username.isEmpty || !targets.isEmpty {
                    contacts.append(Contact(name: username, dialTarget: targets))
                }
            default:
                print("ignore", ele.tagName)
            }
        }
        return (name, contacts)
    }
}
