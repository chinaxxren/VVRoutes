//
// Created by 赵江明 on 2022/3/3.
// Copyright (c) 2022 北京挖趣智慧有限公司. All rights reserved.
//

import Foundation

extension String {
    func toURLParameterDict() -> [String: String] {
        var parameters = [String: String]()

        if count > 0, rangeOfCharacter(from: CharacterSet(charactersIn: "=")) != nil {
            let keyValuePairs = components(separatedBy: CharacterSet(charactersIn: "&"))
            for keyValuePair in keyValuePairs {
                let pair = keyValuePair.components(separatedBy: CharacterSet(charactersIn: "="))
                let paramValue = pair.count == 2 ? pair[1] : ""
                parameters[pair[0]] = paramValue.toURLDecodedString()
            }
        }

        return parameters
    }

    func toURLDecodedString() -> String? {
        let input = VVRoutes.shouldDecodePlusSymbols ? replacingOccurrences(of: "+", with: " ", options: [String.CompareOptions.caseInsensitive], range: startIndex ..< endIndex) : self
        return input.removingPercentEncoding
    }
}

extension URL {
    func fragmentPathComponents() -> [String]? {
        guard let fragment = fragment else {
            return nil
        }
        let url = URL(string: fragment)
        return url?.pathComponents
    }

    func fragmentQuery() -> String? {
        guard let fragment = fragment else {
            return nil
        }
        let url = URL(string: fragment)
        return url?.query
    }
}

extension Dictionary {
    static func += (lhs: inout [Key: Value], rhs: [Key: Value]) {
        lhs.merge(rhs) { $1 }
    }

    static func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        return lhs.merging(rhs) { $1 }
    }

    mutating func mergeOther(_ dict: [Key: Value]) {
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}

extension Array {
    func allOrderedCombinations() -> [String] {
        guard let self = self as? [String] else {
            return [String]()
        }

        var objects = [""]

        for i in 0 ..< count {
            let currentStr = self[i]
            objects.append(currentStr)

            for j in 1 ..< count {
                var q = i + j
                while q < count {
                    let str = q == i + j ? currentStr + self[q] : objects[objects.count - 1] + self[q]
                    objects.append(str)
                    q = q + 1
                }
            }
        }

        return objects
    }
}
