//
//  Decoder.swift
//  AGTraceParser
//
//  Created by Nickolas Pokhylets on 16/12/2025.
//
import Foundation

enum DecoderError: Error {
    case eof
}

struct Decoder {
    var data: Data
    var position: Int = 0
    
    var isAtEnd: Bool {
        return position >= data.count
    }
    
    mutating func decodeVariant() throws(DecoderError) -> UInt {
        var x: UInt = 0
        var shift = 0
        while (true) {
            let b = UInt(try readByte())
            x |= ((b & 0x7F) << shift)
            shift += 7
            if (b & 0x80) == 0 { break }
        }
        return x
    }
    
    mutating func decodeFixed64() throws(DecoderError) -> UInt64 {
        var x: UInt64 = 0
        for i in 0..<8 {
            let b = UInt8(try readByte())
            x |= UInt64(b) << (8 * i)
        }
        return x
    }
    
    mutating func decodeLengthDelimited() throws(DecoderError) -> Data {
        let length = Int(try decodeVariant())
        guard position + length <= data.count else {
            throw .eof
        }
        let startIndex = position
        position += Int(length)
        return Data(data[startIndex..<position])
    }
    
    private mutating func readByte() throws(DecoderError) -> UInt8 {
        guard position < data.count else {
            throw .eof
        }
        let result = data[position]
        position += 1
        return result
    }
    
    
}
