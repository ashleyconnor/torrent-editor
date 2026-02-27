//
//  BencodeParser.swift
//  Torrent Editor
//
//  Created by Ashley Connor on 23/02/2026.
//

import Foundation

enum BencodeValue {
  case integer(Int)
  case string(Data)
  case list([BencodeValue])
  case dictionary([String: BencodeValue])
}

enum BencodeError: LocalizedError {
  case invalidFormat
  case unexpectedEndOfData
  case invalidInteger
  case invalidString
  case invalidDictionary
  case missingKey(String)
  case invalidType(expected: String)

  var errorDescription: String? {
    switch self {
    case .invalidFormat: return "Invalid bencode format"
    case .unexpectedEndOfData: return "Unexpected end of data"
    case .invalidInteger: return "Invalid integer format"
    case .invalidString: return "Invalid string format"
    case .invalidDictionary: return "Invalid dictionary format"
    case .missingKey(let key): return "Missing required key: \(key)"
    case .invalidType(let expected): return "Invalid type, expected: \(expected)"
    }
  }
}

struct BencodeParser {
  private let data: Data
  private var position = 0

  private init(data: Data) {
    self.data = data
  }

  // MARK: - Parsing

  static func decode(_ data: Data) throws -> BencodeValue {
    var parser = BencodeParser(data: data)
    return try parser.parseValue()
  }

  private mutating func parseValue() throws -> BencodeValue {
    guard position < data.count else {
      throw BencodeError.unexpectedEndOfData
    }

    switch data[position] {
    case UInt8(ascii: "i"):
      return try parseInteger()
    case UInt8(ascii: "l"):
      return try parseList()
    case UInt8(ascii: "d"):
      return try parseDictionary()
    case UInt8(ascii: "0")...UInt8(ascii: "9"):
      return try parseString()
    default:
      throw BencodeError.invalidFormat
    }
  }

  private mutating func parseInteger() throws -> BencodeValue {
    position += 1  // Skip 'i'

    guard let endIndex = data[position...].firstIndex(of: UInt8(ascii: "e")) else {
      throw BencodeError.invalidInteger
    }

    guard let integerString = String(data: data[position..<endIndex], encoding: .utf8),
      let integer = Int(integerString)
    else {
      throw BencodeError.invalidInteger
    }

    position = endIndex + 1
    return .integer(integer)
  }

  private mutating func parseString() throws -> BencodeValue {
    guard let colonIndex = data[position...].firstIndex(of: UInt8(ascii: ":")) else {
      throw BencodeError.invalidString
    }

    guard let lengthString = String(data: data[position..<colonIndex], encoding: .utf8),
      let length = Int(lengthString), length >= 0
    else {
      throw BencodeError.invalidString
    }

    position = colonIndex + 1

    guard position + length <= data.count else {
      throw BencodeError.unexpectedEndOfData
    }

    let stringData = data.subdata(in: position..<position + length)
    position += length

    return .string(stringData)
  }

  private mutating func parseList() throws -> BencodeValue {
    position += 1  // Skip 'l'

    var list: [BencodeValue] = []

    while position < data.count && data[position] != UInt8(ascii: "e") {
      let value = try parseValue()
      list.append(value)
    }

    guard position < data.count else {
      throw BencodeError.unexpectedEndOfData
    }

    position += 1  // Skip 'e'
    return .list(list)
  }

  private mutating func parseDictionary() throws -> BencodeValue {
    position += 1  // Skip 'd'

    var dict: [String: BencodeValue] = [:]

    while position < data.count && data[position] != UInt8(ascii: "e") {
      // Keys must be bencode strings (digit-prefixed length)
      guard data[position] >= UInt8(ascii: "0"), data[position] <= UInt8(ascii: "9") else {
        throw BencodeError.invalidDictionary
      }

      guard let colonIndex = data[position...].firstIndex(of: UInt8(ascii: ":")) else {
        throw BencodeError.invalidDictionary
      }

      guard let lengthString = String(data: data[position..<colonIndex], encoding: .utf8),
        let length = Int(lengthString), length >= 0
      else {
        throw BencodeError.invalidDictionary
      }

      let keyStart = colonIndex + 1
      guard keyStart + length <= data.count else {
        throw BencodeError.unexpectedEndOfData
      }

      guard let key = String(data: data[keyStart..<keyStart + length], encoding: .utf8) else {
        throw BencodeError.invalidDictionary
      }

      position = keyStart + length

      let value = try parseValue()
      dict[key] = value
    }

    guard position < data.count else {
      throw BencodeError.unexpectedEndOfData
    }

    position += 1  // Skip 'e'
    return .dictionary(dict)
  }

  // MARK: - Encoding

  static func encode(_ value: BencodeValue) -> Data {
    var data = Data()
    encode(value, to: &data)
    return data
  }

  private static func encode(_ value: BencodeValue, to data: inout Data) {
    switch value {
    case .integer(let int):
      data.append(contentsOf: "i\(int)e".utf8)

    case .string(let stringData):
      data.append(contentsOf: "\(stringData.count):".utf8)
      data.append(stringData)

    case .list(let list):
      data.append(UInt8(ascii: "l"))
      for item in list {
        encode(item, to: &data)
      }
      data.append(UInt8(ascii: "e"))

    case .dictionary(let dict):
      data.append(UInt8(ascii: "d"))
      // Dictionary keys must be sorted in bencode
      for key in dict.keys.sorted() {
        // Encode key
        let keyData = key.data(using: .utf8)!
        data.append(contentsOf: "\(keyData.count):".utf8)
        data.append(keyData)
        // Encode value
        encode(dict[key]!, to: &data)
      }
      data.append(UInt8(ascii: "e"))
    }
  }
}

// MARK: - Helper Extensions

extension BencodeValue {
  var integerValue: Int? {
    if case .integer(let value) = self {
      return value
    }
    return nil
  }

  var stringValue: String? {
    if case .string(let data) = self {
      return String(data: data, encoding: .utf8)
    }
    return nil
  }

  var dataValue: Data? {
    if case .string(let data) = self {
      return data
    }
    return nil
  }

  var listValue: [BencodeValue]? {
    if case .list(let list) = self {
      return list
    }
    return nil
  }

  var dictionaryValue: [String: BencodeValue]? {
    if case .dictionary(let dict) = self {
      return dict
    }
    return nil
  }

  subscript(key: String) -> BencodeValue? {
    if case .dictionary(let dict) = self {
      return dict[key]
    }
    return nil
  }
}
