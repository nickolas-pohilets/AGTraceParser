//
//  TraceDecoder.swift
//  AGTraceParser
//
//  Created by Nickolas Pokhylets on 16/12/2025.
//
import Foundation

enum TraceDecoderError: Error {
    case invalidFormat(String)
    case eof
}

struct TraceDecoder {
    var decoder: Decoder
    var peekedVariant: UInt? = nil
    
    mutating func decodeAll() throws(TraceDecoderError) {
        while !decoder.isAtEnd {
            let pos = decoder.position
            let sep = try self.decodeVariant()
            let chunk = try decodeLengthDelimited()
            var child = TraceDecoder(decoder: Decoder(data: chunk))
            if sep == 0x0A {
                try child.decodeRecord()
            } else if sep == 0x12 {
                try child.decodeSubgraph()
            } else if sep == 0x3a {
                try child.decodeTree()
            } else if sep == 0x1a {
                try child.decodeTypes()
            } else if sep == 0x22 {
                try child.decodeKeys()
            } else {
                child.skipTillEnd("Unknown top-level record type 0x\(sep, hexWidth: 2) @\(pos)")
            }
        }
        print("Done!")
    }
    
    mutating func decodeRecord() throws(TraceDecoderError) {
        let magic08 = try decodeVariant()
        if magic08 != 0x08 {
            print("Unexpected record magic: \(magic08, hexWidth: 2))")
            return
        }
        let kind = try self.decodeVariant()
        switch kind {
        case 0x01:
            try self.decodeBeginTrace()
        case 0x02:
            try self.decodeEndTrace()
        case 0x03:
            try self.decodeBeginUpdateSubgraph()
        case 0x04:
            try self.decodeEndUpdateSubgraph()
        case 0x05:
            try self.decodeBeginUpdateStack()
        case 0x06:
            try self.decodeEndUpdateStack()
        case 0x07:
            try self.decodeBeginUpdateNode()
        case 0x08:
            try self.decodeEndUpdateNode()
        case 0x09:
            try self.decodeBeginUpdateContext()
        case 0x0a:
            try self.decodeEndUpdateContext()
        case 0x0b:
            try self.decodeBeginInvalidation()
        case 0x0c:
            try self.decodeEndInvalidation()
        case 0x0d:
            try self.decodeBeginModify()
        case 0x0e:
            try self.decodeEndModify()
        case 0x0f:
            try self.decodeBeginEvent()
        case 0x10:
            try self.decodeEndEvent()
        case 0x11:
            try self.decodeSnapshotStart()
        case 0x12:
            try self.decodeSnapshotEnd()
        case 0x20:
            try self.decodeCreatedContext()
        case 0x21:
            try self.decodeDestroyContext()
        case 0x22:
            try self.decodeNeedsUpdateContext()
        case 0x23:
            try self.decodeCreatedSubgraph()
        case 0x24:
            try self.decodeInvalidateSubgraph()
        case 0x25:
            try self.decodeAddChildSubgraph()
        case 0x26:
            try self.decodeRemoveChildSubgraph()
        case 0x27:
            try self.decodeAddedNode()
        case 0x28:
            try self.decodeSetDirty()
        case 0x29:
            try self.decodeSetPending()
        case 0x2a:
            try self.decodeSetValue()
        case 0x2b:
            try self.decodeMarkValue()
        case 0x2c:
            try self.decodeAddedIndirectNode()
        case 0x2d:
            try self.decodeSetSource()
        case 0x2e:
            try self.decodeSetDependency()
        case 0x2f:
            try self.decodeAddEdge()
        case 0x30:
            try self.decodeRemoveEdge()
        case 0x31:
            try self.decodeSetEdgePending()
        case 0x32:
            try self.decodeMarkProfile()
        case 0x34:
            try self.decodeCustomEvent()
        case 0x35:
            try self.decodeDestroySubgraph()
        case 0x36:
            try self.decodeNamedEvent()
        case 0x37:
            try self.decodeSetDeadline()
        case 0x38:
            try self.decodePassedDeadline()
        default:
            throw .invalidFormat("Unexpected record kind: \(kind, hexWidth: 2)")
        }
    }
    
    mutating func decodeBeginTrace() throws(TraceDecoderError) {
        try decodeEvent("begin_trace", hasTimestampt: true, numArgs: 0)
    }
    
    mutating func decodeEndTrace() throws(TraceDecoderError) {
        try decodeEvent("end_trace", hasTimestampt: true, numArgs: 0)
    }
    
    mutating func decodeBeginUpdateSubgraph() throws(TraceDecoderError) {
        try decodeEvent("begin_update_subgraph", numArgs: 2)
    }
    
    mutating func decodeEndUpdateSubgraph() throws(TraceDecoderError) {
        try decodeEvent("end_update_subgraph", numArgs: 1)
    }
    
    mutating func decodeBeginUpdateStack() throws(TraceDecoderError) {
        try decodeEvent("begin_update_stack", numArgs: 2)
    }
    
    mutating func decodeEndUpdateStack() throws(TraceDecoderError) {
        try decodeEvent("end_update_stack", numArgs: 2)
    }
    
    mutating func decodeBeginUpdateNode() throws(TraceDecoderError) {
        try decodeEvent("begin_update_node", numArgs: 1)
    }
    
    mutating func decodeEndUpdateNode() throws(TraceDecoderError) {
        try decodeEvent("end_update_node", numArgs: 2)
    }
    
    mutating func decodeBeginUpdateContext() throws(TraceDecoderError) {
        skipTillEnd("begin_udate_context")
    }
    
    mutating func decodeEndUpdateContext() throws(TraceDecoderError) {
        skipTillEnd("end_update_context")
    }
    
    mutating func decodeBeginInvalidation() throws(TraceDecoderError) {
        try decodeEvent("begin_invalidation", numArgs: 2)
    }
    
    mutating func decodeEndInvalidation() throws(TraceDecoderError) {
        try decodeEvent("end_invalidation", numArgs: 2)
    }
    
    mutating func decodeBeginModify() throws(TraceDecoderError) {
        try decodeEvent("begin_modify", hasTimestampt: true, numArgs: 1)
    }
    
    mutating func decodeEndModify() throws(TraceDecoderError) {
        try decodeEvent("end_modify", hasTimestampt: true, numArgs: 1)
    }
    
    mutating func decodeBeginEvent() throws(TraceDecoderError) {
        skipTillEnd("begin_event")
    }
    
    mutating func decodeEndEvent() throws(TraceDecoderError) {
        skipTillEnd("end_event")
    }
    
    mutating func decodeSnapshotStart() throws(TraceDecoderError) {
        try decodeEvent("snapshot_start", hasTimestampt: true, numArgs: 0)
    }
    
    mutating func decodeSnapshotEnd() throws(TraceDecoderError) {
        try decodeEvent("snapshot_end", hasTimestampt: true, numArgs: 0)
    }

    mutating func decodeCreatedContext() throws(TraceDecoderError) {
        skipTillEnd("created_context")
    }
    
    mutating func decodeDestroyContext() throws(TraceDecoderError) {
        skipTillEnd("destroy_context")
    }
    
    mutating func decodeNeedsUpdateContext() throws(TraceDecoderError) {
        skipTillEnd("needs_update_context")
    }
    
    mutating func decodeCreatedSubgraph() throws(TraceDecoderError) {
        try decodeEvent("add_child_subgraph", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeInvalidateSubgraph() throws(TraceDecoderError) {
        try decodeEvent("invalidate_subgraph", hasTimestampt: false, numArgs: 1)
    }
    
    mutating func decodeAddChildSubgraph() throws(TraceDecoderError) {
        try decodeEvent("add_child_subgraph", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeRemoveChildSubgraph() throws(TraceDecoderError) {
        try decodeEvent("remove_child_subgraph", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeAddedNode() throws(TraceDecoderError) {
        try decodeEvent("added_node", hasTimestampt: false, numArgs: 3)
    }
    
    mutating func decodeSetDirty() throws(TraceDecoderError) {
        try decodeEvent("set_dirty", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeSetPending() throws(TraceDecoderError) {
        try decodeEvent("set_pending", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeSetValue() throws(TraceDecoderError) {
        try decodeEvent("set_value", hasTimestampt: false, numArgs: 1)
    }
    
    mutating func decodeMarkValue() throws(TraceDecoderError) {
        try decodeEvent("mark_value", hasTimestampt: false, numArgs: 1)
    }
    
    mutating func decodeAddedIndirectNode() throws(TraceDecoderError) {
        try decodeEvent("added_indirect_node", hasTimestampt: false, numArgs: 4)
    }
    
    mutating func decodeSetSource() throws(TraceDecoderError) {
        try decodeEvent("set_source", hasTimestampt: false, numArgs: 3)
    }
    
    mutating func decodeSetDependency() throws(TraceDecoderError) {
        try decodeEvent("set_dependency", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeAddEdge() throws(TraceDecoderError) {
        try decodeEvent("add_edge", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeRemoveEdge() throws(TraceDecoderError) {
        try decodeEvent("remove_edge", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeSetEdgePending() throws(TraceDecoderError) {
        try decodeEvent("set_endge_pending", hasTimestampt: false, numArgs: 3)
    }
    
    mutating func decodeMarkProfile() throws(TraceDecoderError) {
        skipTillEnd("mark_profile")
    }
    
    mutating func decodeCustomEvent() throws(TraceDecoderError) {
        skipTillEnd("custom_event")
    }
    
    mutating func decodeDestroySubgraph() throws(TraceDecoderError) {
        try decodeEvent("destroy_subgraph", hasTimestampt: false, numArgs: 1)
    }
    
    mutating func decodeNamedEvent() throws(TraceDecoderError) {
        skipTillEnd("named_event")
    }
    
    mutating func decodeSetDeadline() throws(TraceDecoderError) {
        skipTillEnd("set_deadline")
    }
    
    mutating func decodePassedDeadline() throws(TraceDecoderError) {
        skipTillEnd("passed_deadline")
    }
    
    mutating func decodeEvent(_ name: String, hasTimestampt: Bool = true, numArgs: Int) throws(TraceDecoderError) {
        var message = name + ":"
        if hasTimestampt {
            let ts = try decodeFieldTimestamp()
            message += " \(ts)"
        }
        
        for i in 0..<numArgs {
            let X = try decodeVariantIfPresent(tag: 0x18 + 8 * UInt(i))
            message += " \(X as Any)"
        }
        
        try decodeFieldBackTrace(param: 8)
        try assertAtEnd()
        
        print(message)
    }
    
    mutating func decodeSubgraph() throws(TraceDecoderError) {
        skipTillEnd("subgraph")
    }
    
    mutating func decodeTree() throws(TraceDecoderError) {
        skipTillEnd("tree")
    }
    
    mutating func decodeTypes() throws(TraceDecoderError) {
        skipTillEnd("types")
    }
    
    mutating func decodeKeys() throws(TraceDecoderError) {
        skipTillEnd("keys")
    }
    
    mutating func decodeFieldTimestamp() throws(TraceDecoderError) -> Date {
        let magic11 = try decodeVariant()
        if magic11 != 0x11 {
            throw .invalidFormat("Unexpected field timestampt magic: \(magic11, hexWidth: 2))")
        }
        let ts = try decodeDouble()
        return Date(timeIntervalSinceReferenceDate: ts)
    }
    
    mutating func decodeFieldBackTrace(param: UInt) throws(TraceDecoderError) {
        if decoder.isAtEnd {
            return
        }
        let tag = try decodeVariant()
        let expectedTag = 2+8*param
        if tag != expectedTag {
            throw .invalidFormat("Unexpected leading tag for field backtrace: \(tag) vs \(expectedTag)")
        }
        skipTillEnd("field_backtrace")
    }
    
    private mutating func decodeVariantIfPresent(tag: UInt) throws(TraceDecoderError) -> UInt? {
        if try peekVariant() == tag {
            self.peekedVariant = nil
            return try decodeVariantImpl()
        }
        return nil
    }

    private mutating func decodeVariant() throws(TraceDecoderError) -> UInt {
        if let peekedVariant {
            self.peekedVariant = nil
            return peekedVariant
        }
        return try decodeVariantImpl()
    }
    
    private mutating func decodeVariantImpl() throws(TraceDecoderError) -> UInt {
        return try mappingError { () throws(DecoderError) -> UInt in
            try decoder.decodeVariant()
        }
    }
    
    private mutating func decodeFixed64() throws(TraceDecoderError) -> UInt64 {
        return try mappingError { () throws(DecoderError) -> UInt64 in
            try decoder.decodeFixed64()
        }
    }
    
    private mutating func decodeDouble() throws(TraceDecoderError) -> Double {
        let bits = try decodeFixed64()
        return Double(bitPattern: bits)
    }
    
    private mutating func decodeLengthDelimited() throws(TraceDecoderError) -> Data {
        return try mappingError { () throws(DecoderError) -> Data in
            try decoder.decodeLengthDelimited()
        }
    }
    
    private func mappingError<T>( _ block: () throws(DecoderError) -> T) throws(TraceDecoderError) -> T {
        do {
            return try block()
        } catch let e {
            switch e {
            case .eof: throw .eof
            }
        }
    }
    
    private func assertAtEnd() throws(TraceDecoderError) {
        if !decoder.isAtEnd {
            throw .invalidFormat("Unexpected extra content")
        }
    }
    
    private mutating func skipTillEnd(_ context: String) {
        print("SKIP: \(context) <\(decoder.data.count - decoder.position) bytes>")
        decoder.position = decoder.data.count
    }
    
    private mutating func peekVariant() throws(TraceDecoderError) -> UInt? {
        if let peekedVariant { return peekedVariant }
        if decoder.isAtEnd { return nil }
        let result = try decodeVariantImpl()
        peekedVariant = result
        return result
    }
    
    // ["0xa", "0x12", "0x1a", "0x22"]
}


extension DefaultStringInterpolation {
    mutating func appendInterpolation<T: BinaryInteger>(_ value: T, hexWidth: Int) {
        var s = String(value, radix: 16, uppercase: true)
        let n = hexWidth - s.count
        if n > 0 {
            var padding: String = ""
            for _ in 0..<n {
                padding.append("0")
            }
            s = padding + s
        }
        appendInterpolation(s)
    }
}
