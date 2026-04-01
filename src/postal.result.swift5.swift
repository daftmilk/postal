#!/usr/bin/env swift

import Foundation
import Contacts

func phpCompatHtmlspecialchars(string: String) -> String {
    var newString = string
    let charDictionary = [
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        "\"": "&quot;",
        "'": "&apos;"
    ]
    for (unescapedChar, escapedChar) in charDictionary {
        newString = newString.replacingOccurrences(of: unescapedChar, with: escapedChar)
    }
    return newString
}

func isGermanLocale() -> Bool {
    let preferredLanguage = Locale.preferredLanguages.first ?? ""
    return preferredLanguage.lowercased().hasPrefix("de")
}

func shouldFormatAsGerman(_ addr: CNPostalAddress) -> Bool {
    let country = addr.country.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    if country == "deutschland" || country == "germany" {
        return true
    }

    if country.isEmpty && isGermanLocale() {
        return true
    }

    return false
}

func formatGermanAddress(_ addr: CNPostalAddress) -> String {
    var lines: [String] = []

    let street = addr.street.trimmingCharacters(in: .whitespacesAndNewlines)
    if !street.isEmpty {
        lines.append(street)
    }

    let postalCode = addr.postalCode.trimmingCharacters(in: .whitespacesAndNewlines)
    let city = addr.city.trimmingCharacters(in: .whitespacesAndNewlines)
    let state = addr.state.trimmingCharacters(in: .whitespacesAndNewlines)
    let country = addr.country.trimmingCharacters(in: .whitespacesAndNewlines)

    let postalCity = [postalCode, city]
        .filter { !$0.isEmpty }
        .joined(separator: " ")

    if !postalCity.isEmpty {
        lines.append(postalCity)
    }

    if !state.isEmpty {
        lines.append(state)
    }

    if !country.isEmpty {
        lines.append(country)
    }

    return lines.joined(separator: "\n")
}

func formatAddress(_ addr: CNPostalAddress) -> String {
    if shouldFormatAsGerman(addr) {
        return formatGermanAddress(addr)
    } else {
        let formatter = CNPostalAddressFormatter()
        return formatter.string(from: addr)
    }
}

let arguments: [String] = CommandLine.arguments.count <= 1 ? [] : Array(CommandLine.arguments.dropFirst())
if arguments.count != 1 {
    print("This application expects exactly 1 argument. If you use spaces, wrap the one argument in double quotes, please.")
    exit(EXIT_FAILURE)
}

let response = CommandLine.arguments[1]

if #available(OSX 10.11, *) {

    let store = CNContactStore()
    let keysToFetch = [
        CNContactJobTitleKey as CNKeyDescriptor,
        CNContactNamePrefixKey as CNKeyDescriptor,
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactNameSuffixKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactPostalAddressesKey as CNKeyDescriptor
    ]

    let contacts = try store.unifiedContacts(
        matching: CNContact.predicateForContacts(matchingName: response),
        keysToFetch: keysToFetch
    )

    var xml = "<?xml version=\"1.0\"?><items>"

    for contact in contacts {
        if contact.postalAddresses.count > 0 {
            let addresses = contact.postalAddresses

            for address in addresses {
                let addr = address.value
                let formattedAddress = formatAddress(addr)

                var strName = ""

                if !contact.givenName.isEmpty || !contact.familyName.isEmpty {
                    if !contact.namePrefix.isEmpty {
                        strName += contact.namePrefix + " "
                    }
                    strName += contact.givenName + " " + contact.familyName
                    if !contact.nameSuffix.isEmpty {
                        strName += " " + contact.nameSuffix
                    }
                    strName += "\n"
                }

                if !contact.organizationName.isEmpty {
                    strName += contact.organizationName + "\n"
                }

                let title = phpCompatHtmlspecialchars(string: strName)
                let description = phpCompatHtmlspecialchars(
                    string: formattedAddress.replacingOccurrences(of: "\n", with: ", ")
                )

                var arg = (strName + formattedAddress).replacingOccurrences(of: "\n", with: ";")
                arg = phpCompatHtmlspecialchars(string: arg)

                xml += "<item arg=\"\(arg)\" valid=\"yes\"><title>\(title)</title><subtitle>\(description)</subtitle></item>"
            }
        }
    }

    xml += "</items>"
    print(xml)

    exit(EXIT_SUCCESS)

} else {
    print("You need Mac Os X 10.11 or newer.")
}