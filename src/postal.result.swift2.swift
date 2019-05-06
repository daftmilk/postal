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
        newString = newString.stringByReplacingOccurrencesOfString(unescaped_char, withString: escaped_char, options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
    }
    return newString
}

if(Process.arguments.count != 2){
    print("this application expects exactly 1 argument. If you use spaces, wrap the one argument in double quotes, please.")
    exit(EXIT_FAILURE)
}

let response = Process.arguments[1];

// check is mandatory…
if #available(OSX 10.11, *) {
    
    
    let store = CNContactStore()
    
    let contacts = try store.unifiedContactsMatchingPredicate(CNContact.predicateForContactsMatchingName(response), keysToFetch:[
        CNContactJobTitleKey,
        CNContactNamePrefixKey,
        CNContactGivenNameKey,
        CNContactFamilyNameKey,
        CNContactNameSuffixKey,
        CNContactOrganizationNameKey,
        CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName),
        CNContactPostalAddressesKey
        ])
    
    let formatter = CNContactFormatter()
    formatter.style = .FullName
    
    var xml = "<?xml version=\"1.0\"?><items>"
    
    for contact in contacts {
        
        if(contact.postalAddresses.count > 0){
            
            let addresses = contact.postalAddresses
            let addressFormatter = CNPostalAddressFormatter()
            for address in addresses {
                
                let addr = address.value as! CNPostalAddress
                let formattedAddress = addressFormatter.stringFromPostalAddress(addr)
                
                var str_name = ""
                var str_addr = ""
                
                if(contact.givenName.characters.count > 0 || contact.familyName.characters.count > 0){
                    if(contact.namePrefix.characters.count > 0){
                        str_name = str_name + contact.namePrefix + " "
                    }
                    str_name = str_name + contact.givenName + " " + contact.familyName
                    if(contact.nameSuffix.characters.count > 0){
                        str_name = str_name + " " + contact.nameSuffix
                    }
                    str_name = str_name + "\n"
                }
                
                if(contact.organizationName.characters.count > 0){
                    str_name = str_name + contact.organizationName + "\n"
                }

                str_addr = formattedAddress.stringByReplacingOccurrencesOfString("\n", withString: ";")
                var title = phpCompatHtmlspecialchars(str_name)
                var description = phpCompatHtmlspecialchars(formattedAddress.stringByReplacingOccurrencesOfString("\n", withString: ", "))
                var arg = (str_name + formattedAddress).stringByReplacingOccurrencesOfString("\n", withString: ";")
                arg = phpCompatHtmlspecialchars(arg)
                xml = xml + "<item arg=\"\(arg)\" valid=\"yes\"><title>\(title)</title><subtitle>\(description)</subtitle></item>"
                
            }
            
            
        }
        
        
    }

    xml = xml + "</xml>"
    print(xml)

    exit(EXIT_SUCCESS)
}   else {
    print("You need Mac Os X 10.11 or newer")
}


