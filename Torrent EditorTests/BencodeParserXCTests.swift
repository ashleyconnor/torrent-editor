//
//  BencodeParserXCTests.swift
//  Torrent Editor Tests
//
//  Created by Ashley Connor on 23/02/2026.
//

import XCTest
@testable import Torrent_Editor

final class BencodeParserXCTests: XCTestCase {
    
    func testParseInteger() throws {
        let data = "i42e".data(using: .utf8)!
        let result = try BencodeParser.decode(data)
        
        XCTAssertEqual(result.integerValue, 42)
    }
    
    func testParseNegativeInteger() throws {
        let data = "i-42e".data(using: .utf8)!
        let result = try BencodeParser.decode(data)
        
        XCTAssertEqual(result.integerValue, -42)
    }
    
    func testParseString() throws {
        let data = "5:hello".data(using: .utf8)!
        let result = try BencodeParser.decode(data)
        
        XCTAssertEqual(result.stringValue, "hello")
    }
    
    func testParseList() throws {
        let data = "li42e5:helloe".data(using: .utf8)!
        let result = try BencodeParser.decode(data)
        
        guard let list = result.listValue else {
            XCTFail("Expected list value")
            return
        }
        
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list[0].integerValue, 42)
        XCTAssertEqual(list[1].stringValue, "hello")
    }
    
    func testParseDictionary() throws {
        let data = "d3:foo3:bar3:bazi42ee".data(using: .utf8)!
        let result = try BencodeParser.decode(data)
        
        guard let dict = result.dictionaryValue else {
            XCTFail("Expected dictionary value")
            return
        }
        
        XCTAssertEqual(dict["foo"]?.stringValue, "bar")
        XCTAssertEqual(dict["baz"]?.integerValue, 42)
    }
    
    func testEncodeInteger() throws {
        let value = BencodeValue.integer(42)
        let data = BencodeParser.encode(value)
        let string = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(string, "i42e")
    }
    
    func testEncodeString() throws {
        let value = BencodeValue.string("hello".data(using: .utf8)!)
        let data = BencodeParser.encode(value)
        let string = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(string, "5:hello")
    }
    
    func testEncodeList() throws {
        let value = BencodeValue.list([
            .integer(42),
            .string("hello".data(using: .utf8)!)
        ])
        let data = BencodeParser.encode(value)
        let string = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(string, "li42e5:helloe")
    }
    
    func testEncodeDictionary() throws {
        let value = BencodeValue.dictionary([
            "foo": .string("bar".data(using: .utf8)!),
            "baz": .integer(42)
        ])
        let data = BencodeParser.encode(value)
        let string = String(data: data, encoding: .utf8)
        
        // Dictionary keys should be sorted
        XCTAssertEqual(string, "d3:bazi42e3:foo3:bare")
    }
    
    func testRoundTripEncodingAndDecoding() throws {
        let original = BencodeValue.dictionary([
            "announce": .string("http://tracker.example.com:8080/announce".data(using: .utf8)!),
            "creation date": .integer(1234567890),
            "info": .dictionary([
                "name": .string("example".data(using: .utf8)!),
                "piece length": .integer(262144),
                "length": .integer(1024000)
            ])
        ])
        
        let encoded = BencodeParser.encode(original)
        let decoded = try BencodeParser.decode(encoded)
        
        guard let decodedDict = decoded.dictionaryValue else {
            XCTFail("Expected dictionary")
            return
        }
        
        XCTAssertEqual(decodedDict["announce"]?.stringValue, "http://tracker.example.com:8080/announce")
        XCTAssertEqual(decodedDict["creation date"]?.integerValue, 1234567890)
        XCTAssertEqual(decodedDict["info"]?["name"]?.stringValue, "example")
    }
}
