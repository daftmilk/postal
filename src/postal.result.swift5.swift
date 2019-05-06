#!/usr/bin/env xcrun swift

import Foundation
import Contacts

func phpCompatHtmlspecialchars(string: String) -> String {
    var newString = string
    let char_dictionary = [
        "&" : "&amp;",
        "<" : "&lt;",
        ">" : "&gt;",
        "\"" : "&quot;",
         "'" : "&apos;"
    ];
    for (unescaped_char, escaped_char) in char_dictionary {
        newString = newString.replacingOccurrences(of: unescaped_char, with: escaped_char)
    }
    return newString
}

let arguments: [String] = CommandLine.arguments.count <= 1 ? [] : Array(CommandLine.arguments.dropFirst())
if(arguments.count != 1){
    print("This application expects exactly 1 argument. If you use spaces, wrap the one argument in double quotes, please.")
    exit(EXIT_FAILURE)
}

let response = CommandLine.arguments[1];

// check is mandatory…
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
    let contacts = try store.unifiedContacts(matching: CNContact.predicateForContacts(matchingName: response), keysToFetch: keysToFetch)

    
    let formatter = CNContactFormatter()
    formatter.style = .fullName
    
    
    var xml = "<?xml version=\"1.0\"?><items>"
    
    for contact in contacts {
        
        
        if(contact.postalAddresses.count > 0){
            
            let addresses = contact.postalAddresses
            let addressFormatter = CNPostalAddressFormatter()
            for address in addresses {
                
                //warning: forced cast of 'CNPostalAddress' to same type has no effect
                let addr = address.value
                let formattedAddress = addressFormatter.string(from: addr)
                var str_name = ""
                
                if(!contact.givenName.isEmpty || !contact.familyName.isEmpty){
                    if(!contact.namePrefix.isEmpty){
                        str_name = str_name + contact.namePrefix + " "
                    }
                    str_name = str_name + contact.givenName + " " + contact.familyName
                    if(!contact.nameSuffix.isEmpty){
                        str_name = str_name + " " + contact.nameSuffix
                    }
                    str_name = str_name + "\n"
                }
                
                if(!contact.organizationName.isEmpty){
                    str_name = str_name + contact.organizationName + "\n"
                }

                let title = phpCompatHtmlspecialchars(string: str_name)
                let description = phpCompatHtmlspecialchars(string: formattedAddress.replacingOccurrences(of: "\n", with: ", "))
                
                var arg = (str_name + formattedAddress).replacingOccurrences(of: "\n", with: ";")
                arg = phpCompatHtmlspecialchars(string: arg)
                xml = xml + "<item arg=\"\(arg)\" valid=\"yes\"><title>\(title)</title><subtitle>\(description)</subtitle></item>"
                
            }
            
            
        }
        
        
    }

    xml = xml + "</xml>"
    print(xml)

    exit(EXIT_SUCCESS)
    
}   else {

    print("You need Mac Os X 10.11 or newer.")

}


