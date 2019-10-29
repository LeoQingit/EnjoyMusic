//
//  Utilities.swift
//  Music
//

import Foundation
import AVFoundation

extension Sequence {
    /// Similar to
    /// ```
    /// func forEach(@noescape body: (Self.Generator.Element) -> ())
    /// ```
    /// but calls the completion block once all blocks have called their completion block. If some of the calls to the block do not call their completion blocks that will result in data leaking.

    func asyncForEach(completion: @escaping () -> (), block: (Iterator.Element, @escaping () -> ()) -> ()) {
        let group = DispatchGroup()
        let innerCompletion = { group.leave() }
        for x in self {
            group.enter()
            block(x, innerCompletion)
        }
        group.notify(queue: DispatchQueue.main, execute: completion)
    }

    func all(_ condition: (Iterator.Element) -> Bool) -> Bool {
        for x in self where !condition(x) {
            return false
        }
        return true
    }

    func some(_ condition: (Iterator.Element) -> Bool) -> Bool {
        for x in self where condition(x) {
            return true
        }
        return false
    }
}


extension Sequence where Iterator.Element: AnyObject {
    public func containsObjectIdentical(to object: AnyObject) -> Bool {
        return contains { $0 === object }
    }
}


extension Array {
    var decomposed: (Iterator.Element, [Iterator.Element])? {
        guard let x = first else { return nil }
        return (x, Array(self[1..<count]))
    }

    func sliced(size: Int) -> [[Iterator.Element]] {
        var result: [[Iterator.Element]] = []
        for idx in stride(from: startIndex, to: endIndex, by: size) {
            let end = Swift.min(idx + size, endIndex)
            result.append(Array(self[idx..<end]))
        }
        return result
    }
}

extension FileManager {
    /// 判断是否是文件夹的方法
    static func directoryIsExists (path: String) -> Bool {
        /// 是否是文件夹
        var directoryExists = ObjCBool(false)
        /// 文件路径是否存在
        let fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &directoryExists)
        return fileExists && directoryExists.boolValue
    }
}


extension URL {
    static var temporary: URL {
        return URL(fileURLWithPath:NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
    }

    static var documents: URL {
        return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    static var library: URL {
        return try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
}


extension String {
    public func removingCharacters(in set: CharacterSet) -> String {
        var chars = self
        for idx in chars.indices.reversed() {
            if set.contains(String(chars[idx]).unicodeScalars.first!) {
                chars.remove(at: idx)
            }
        }
        return String(chars)
    }
    
    static var uuid: String {
        return CFUUIDCreateString(kCFAllocatorDefault, CFUUIDCreate(kCFAllocatorDefault))! as String
    }
    
}

/// 确保重名文件的存储
func checkNameDuplicate(toPath: URL, trimmingValue: inout Int) -> URL? {
    trimmingValue = trimmingValue + 1
    if FileManager.default.fileExists(atPath: toPath.path) {
        guard let fileName = toPath.lastPathComponent.split(separator: ".").first else { return nil }
        var suffix: String = ""
        if toPath.lastPathComponent.split(separator: ".").count > 1 {
            var components = toPath.lastPathComponent.split(separator: ".")
            components.removeFirst()
            suffix = components.joined(separator: ".")
        }
        let newFileName: String
        if trimmingValue == 0 {
            newFileName = String(fileName) + " " + String(trimmingValue) + "." + suffix
        } else {
            var components = fileName.split(separator: " ")
            components.removeLast()
            let newFileNamePre = components.joined(separator: " ")
            newFileName = newFileNamePre + " " + String(trimmingValue) + "." + suffix
        }
        
        var allComponents = toPath.pathComponents
        if allComponents.count > 0 {
            allComponents.removeLast()
        }
        allComponents.append(newFileName)
        let newPathString = allComponents.joined(separator: "/")
        let newURL = URL(fileURLWithPath: newPathString)
        return checkNameDuplicate(toPath: newURL, trimmingValue: &trimmingValue)
    } else {
        return toPath
    }
}

private var lastItemKey: Void?

extension AVPlayer {
    
    // 上一次的Item
     @objc var lastItem: AVPlayerItem? {
        
        get{
            return objc_getAssociatedObject(self, &lastItemKey) as? AVPlayerItem
        }
        
        set(newValue) {
            objc_setAssociatedObject(self, &lastItemKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
    }

}
