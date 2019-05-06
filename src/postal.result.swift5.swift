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
        //swift 2
        //newString = newString.stringByReplacingOccurrencesOfString(unescaped_char, withString: escaped_char, options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
        //swift 3
        newString = newString.replacingOccurrences(of: unescaped_char, with: escaped_char)
    }
    return newString
}

//swift 2
//let arguments: [String] = Process.arguments.count <= 1 ? [] : Array(Process.arguments.dropFirst())
//swift 3
let arguments: [String] = CommandLine.arguments.count <= 1 ? [] : Array(CommandLine.arguments.dropFirst())
if(arguments.count != 1){
    print("this application expects exactly 1 argument. If you use spaces, wrap the one argument in double quotes, please.")
    exit(EXIT_FAILURE)
}

//swift 2
//let response = Process.arguments[1];
//swift 3
let response = CommandLine.arguments[1];

// check is mandatory…
//if #available(OSX 10.11, *) {
if #available(OSX 10.11, *) {
    
    //let authorizationStatus = CNContactGetAuthorizationStatus()
    //switch authorizationStatus {
    //    case .Denied, .Restricted:
    //        //1
    //        print("Denied")
    //    case .Authorized:
    //        //2
    //        print("Authorized")
    //    case .NotDetermined:
    //        //3
    //        print("Not Determined")
    //}
    
    
    let store = CNContactStore()
    let keysToFetch = [
        CNContactJobTitleKey as CNKeyDescriptor,
        CNContactNamePrefixKey as CNKeyDescriptor,
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactNameSuffixKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        //swift 2
        //CNContactFormatter.descriptorForRequiredKeysForStyle(.fullName),
        //swift 3
        //CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
        CNContactPostalAddressesKey as CNKeyDescriptor
    ]
    //swift 2
    //let contacts = try store.unifiedContactsMatchingPredicate(CNContact.predicateForContactsMatchingName(response), keysToFetch: keysToFetch)
    //swift 3
    let contacts = try store.unifiedContacts(matching: CNContact.predicateForContacts(matchingName: response), keysToFetch: keysToFetch)

    
    let formatter = CNContactFormatter()
    //swift 2
    //formatter.style = .FullName
    //swift 3
    formatter.style = .fullName
    
    
    //print(contacts.count);
    var xml = "<?xml version=\"1.0\"?><items>"
    
    for contact in contacts {
        
        
        if(contact.postalAddresses.count > 0){
            
            let addresses = contact.postalAddresses
            let addressFormatter = CNPostalAddressFormatter()
            for address in addresses {
                
                //let addr = address.value as! CNPostalAddress
                //warning: forced cast of 'CNPostalAddress' to same type has no effect
                let addr = address.value

                //swift 2
                //let formattedAddress = addressFormatter.stringFromPostalAddress(addr)
                //swift 3
                let formattedAddress = addressFormatter.string(from: addr)
                //string(from:)
                
                var str_name = ""
                //var str_addr = ""
                
                //if(contact.givenName.characters.count > 0 || contact.familyName.characters.count > 0){
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

                //swift 2
                //str_addr = formattedAddress.stringByReplacingOccurrencesOfString("\n", withString: ";")
                //swift 3
                //str_addr = formattedAddress.replacingOccurrences(of: "\n", with: ";")
                //swift 2
                //var title = phpCompatHtmlspecialchars(str_name)
                //swift 3
                //var title = phpCompatHtmlspecialchars(string: str_name)
                let title = phpCompatHtmlspecialchars(string: str_name)
                //swift 2
                //var description = phpCompatHtmlspecialchars(formattedAddress.stringByReplacingOccurrencesOfString("\n", withString: ", "))
                //swift 3
                //var description = phpCompatHtmlspecialchars(string: formattedAddress.replacingOccurrences(of: "\n", with: ", "))
                let description = phpCompatHtmlspecialchars(string: formattedAddress.replacingOccurrences(of: "\n", with: ", "))
                //swift 2
                //var arg = (str_name + formattedAddress).stringByReplacingOccurrencesOfString("\n", withString: ";")
                //swift 3
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
    print("You need Mac Os X 10.11 or newer")
}


