//
//  ArrayTransformer.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/11/25.
//

import Foundation

@objc(StringArrayTransformer)
class StringArrayTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSArray.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let stringArray = value as? [String] else { return nil }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: stringArray, requiringSecureCoding: true)
            return data
        } catch {
            print("Error encoding string array: \(error)")
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        
        do {
            let stringArray = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data) as? [String]
            return stringArray
        } catch {
            print("Error decoding string array: \(error)")
            return nil
        }
    }
}

// Register the transformer when the app launches
extension StringArrayTransformer {
    static func register() {
        let name = NSValueTransformerName(rawValue: String(describing: StringArrayTransformer.self))
        let transformer = StringArrayTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
