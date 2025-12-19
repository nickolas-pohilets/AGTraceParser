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

class ImageInfo {
    let uuid: UUID
    let path: String
    let baseAddress: UInt
    let size: UInt
    
    init(uuid: UUID, path: String, baseAddress: UInt, size: UInt) {
        self.uuid = uuid
        self.path = path
        self.baseAddress = baseAddress
        self.size = size
    }
}

struct StackFrame {
    var image: ImageInfo
    var offset: UInt
}

struct TraceDecoder {
    typealias E = TraceDecoderError
    
    var decoder: Decoder
    var peekedTag: UInt? = nil
    
    init(data: Data) {
        self.decoder = Decoder(data: data)
        self.peekedTag = nil
    }
    
    mutating func decodeAll() throws(E) {
        while !decoder.isAtEnd {
            let pos = decoder.position
            print("@\(pos, hexWidth: 6)")
            let sep = try self.decodeVarInt()
            var child = try decodeChild()
            if sep == 0x0A {
                try child.decodeRecord()
            } else if sep == 0x12 {
                try child.decodeSubgraph()
            } else if sep == 0x3a {
                try child.decodeTree()
            } else if sep == 0x1a {
                try child.decodeType()
            } else if sep == 0x22 {
                try child.decodeKey()
            } else {
                child.skipTillEnd("Unknown top-level record type 0x\(sep, hexWidth: 2) @\(pos)")
            }
        }
        print("Done!")
    }
    
    mutating func decodeRecord() throws(E) {
        let magic08 = try decodeVarInt()
        if magic08 != 0x08 {
            print("Unexpected record magic: \(magic08, hexWidth: 2))")
            return
        }
        let kind = try self.decodeVarInt()
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
    
    mutating func decodeBeginTrace() throws(E) {
        try decodeEvent("begin_trace", hasTimestampt: true, numArgs: 0)
    }
    
    mutating func decodeEndTrace() throws(E) {
        try decodeEvent("end_trace", hasTimestampt: true, numArgs: 0)
    }
    
    mutating func decodeBeginUpdateSubgraph() throws(E) {
        try decodeEvent("begin_update_subgraph", numArgs: 2)
    }
    
    mutating func decodeEndUpdateSubgraph() throws(E) {
        try decodeEvent("end_update_subgraph", numArgs: 1)
    }
    
    mutating func decodeBeginUpdateStack() throws(E) {
        try decodeEvent("begin_update_stack", numArgs: 2)
    }
    
    mutating func decodeEndUpdateStack() throws(E) {
        try decodeEvent("end_update_stack", numArgs: 2)
    }
    
    mutating func decodeBeginUpdateNode() throws(E) {
        try decodeEvent("begin_update_node", numArgs: 1)
    }
    
    mutating func decodeEndUpdateNode() throws(E) {
        try decodeEvent("end_update_node", numArgs: 2)
    }
    
    mutating func decodeBeginUpdateContext() throws(E) {
        skipTillEnd("begin_udate_context")
    }
    
    mutating func decodeEndUpdateContext() throws(E) {
        skipTillEnd("end_update_context")
    }
    
    mutating func decodeBeginInvalidation() throws(E) {
        try decodeEvent("begin_invalidation", numArgs: 2)
    }
    
    mutating func decodeEndInvalidation() throws(E) {
        try decodeEvent("end_invalidation", numArgs: 2)
    }
    
    mutating func decodeBeginModify() throws(E) {
        try decodeEvent("begin_modify", hasTimestampt: true, numArgs: 1)
    }
    
    mutating func decodeEndModify() throws(E) {
        try decodeEvent("end_modify", hasTimestampt: true, numArgs: 1)
    }
    
    mutating func decodeBeginEvent() throws(E) {
        skipTillEnd("begin_event")
    }
    
    mutating func decodeEndEvent() throws(E) {
        skipTillEnd("end_event")
    }
    
    mutating func decodeSnapshotStart() throws(E) {
        try decodeEvent("snapshot_start", hasTimestampt: true, numArgs: 0)
    }
    
    mutating func decodeSnapshotEnd() throws(E) {
        try decodeEvent("snapshot_end", hasTimestampt: true, numArgs: 0)
    }

    mutating func decodeCreatedContext() throws(E) {
        skipTillEnd("created_context")
    }
    
    mutating func decodeDestroyContext() throws(E) {
        skipTillEnd("destroy_context")
    }
    
    mutating func decodeNeedsUpdateContext() throws(E) {
        skipTillEnd("needs_update_context")
    }
    
    mutating func decodeCreatedSubgraph() throws(E) {
        try decodeEvent("add_child_subgraph", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeInvalidateSubgraph() throws(E) {
        try decodeEvent("invalidate_subgraph", hasTimestampt: false, numArgs: 1)
    }
    
    mutating func decodeAddChildSubgraph() throws(E) {
        try decodeEvent("add_child_subgraph", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeRemoveChildSubgraph() throws(E) {
        try decodeEvent("remove_child_subgraph", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeAddedNode() throws(E) {
        try decodeEvent("added_node", hasTimestampt: false, numArgs: 3)
    }
    
    mutating func decodeSetDirty() throws(E) {
        try decodeEvent("set_dirty", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeSetPending() throws(E) {
        try decodeEvent("set_pending", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeSetValue() throws(E) {
        try decodeEvent("set_value", hasTimestampt: false, numArgs: 1)
    }
    
    mutating func decodeMarkValue() throws(E) {
        try decodeEvent("mark_value", hasTimestampt: false, numArgs: 1)
    }
    
    mutating func decodeAddedIndirectNode() throws(E) {
        try decodeEvent("added_indirect_node", hasTimestampt: false, numArgs: 4)
    }
    
    mutating func decodeSetSource() throws(E) {
        try decodeEvent("set_source", hasTimestampt: false, numArgs: 3)
    }
    
    mutating func decodeSetDependency() throws(E) {
        try decodeEvent("set_dependency", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeAddEdge() throws(E) {
        try decodeEvent("add_edge", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeRemoveEdge() throws(E) {
        try decodeEvent("remove_edge", hasTimestampt: false, numArgs: 2)
    }
    
    mutating func decodeSetEdgePending() throws(E) {
        try decodeEvent("set_endge_pending", hasTimestampt: false, numArgs: 3)
    }
    
    mutating func decodeMarkProfile() throws(E) {
        skipTillEnd("mark_profile")
    }
    
    mutating func decodeCustomEvent() throws(E) {
        skipTillEnd("custom_event")
    }
    
    mutating func decodeDestroySubgraph() throws(E) {
        try decodeEvent("destroy_subgraph", hasTimestampt: false, numArgs: 1)
    }
    
    mutating func decodeNamedEvent() throws(E) {
        skipTillEnd("named_event")
    }
    
    mutating func decodeSetDeadline() throws(E) {
        skipTillEnd("set_deadline")
    }
    
    mutating func decodePassedDeadline() throws(E) {
        skipTillEnd("passed_deadline")
    }
    
    mutating func decodeEvent(_ name: String, hasTimestampt: Bool = true, numArgs: Int) throws(E) {
        var message = name + ":"
        if hasTimestampt {
            let ts = try decodeFieldTimestamp()
            message += " \(ts)"
        }
        
        for i in 0..<numArgs {
            let X = try decodeVarIntIfPresent(tag: 0x18 + 8 * UInt(i))
            message += " \(X, default: "nil")"
        }
        
        _ = try decodeFieldBackTrace(param: 8)
        try assertAtEnd()
        
        print(message)
    }
    
    mutating func decodeSubgraph() throws(E) {
        // subgraph->_w18 & 0x7fffffff
        let x08 = try decodeVarIntIfPresent(tag: 0x08)
        // subgraph->_x30
        let x10 = try decodeVarIntIfPresent(tag: 0x10)
        // if (subgraph->_x38 == 0) {
        //     items = {}
        // } else if ((subgraph->_x38 & 1) == 0) {
        //     items = { subgraph->_x38 }
        // } else {
        //     m = subgraph->_x38 & ~1;
        //     {base, count} = m->_x20
        //     b = base == 0 ? m : base
        //     items = b[0..<count]
        // }
        // Skips zeros during encoding
        let x18 = try decodeArray(tag: 0x18) { (d: inout TraceDecoder) throws(E) in
            try d.decodeVarInt()
        }
        // tagged_pointers = subgraph->_x40[0..<subgraph->_w48]
        // items = tagged_pointers.map { p in
        //    (p & ~3)->w18 & 0x7f_ff_ff_ff
        // }
        // Skips zeros during encoding
        let x20 = try decodeArray(tag: 0x20) { (d: inout TraceDecoder) throws(E) in
            try d.decodeVarInt()
        }
        // item = subgraph->_b68 ? 1 : nil
        let x28: Bool = (try decodeVarIntIfPresent(tag: 0x28) ?? 0) != 0
        
        print("subgraph: \(x08, default: "nil"), \(x10, default: "nil"), \(x18), \(x20), \(x28) {")
        
        // let w8 = subgraph->_w10
        // ...
        let x32: [()] = try decodeArray(tag: 0x32) { (d: inout TraceDecoder) throws(E) in
            var child = try d.decodeChild()
            return try child.decodeSubgraphFoo()
        }
        
        // if (subgraph->w60) {
        //    encode_tree(graph: subgraph->x28, encode: x19, node: subgraph->w60)
        // }
        let x3a: ()? = try decodeIfPresent(tag: 0x3a) { (d: inout TraceDecoder) throws(E) in
            var child = try d.decodeChild()
            return try child.decodeTree()
        }
        
        print("}")
    }
    
    mutating func decodeSubgraphFoo() throws(E) {
        let x08 = try decodeVarIntIfPresent(tag: 0x08) ?? 0
        
        if try decodeTag(0x12) {
            print("node: \(x08)")
            var child = try decodeChild()
            try child.decodeNode()
        } else if try decodeTag(0x1a) {
            print("indirectNode: \(x08)")
            var child = try decodeChild()
            try child.decodeIndirectNode()
        } else {
            if let tag = try peekTag() {
                throw .invalidFormat("Unexpected tag for subgraphFoo: \(tag, hexWidth: 2)")
            }
        }
    }

    mutating func decodeNode() throws(E) {
        skipTillEnd("node")
    }
    
    mutating func decodeIndirectNode() throws(E) {
        skipTillEnd("indirectNode")
    }
    
    mutating func decodeTree() throws(E) {
        skipTillEnd("tree")
    }
    
    mutating func decodeType() throws(E) {
        let a = try decodeVarIntIfPresent(tag: 0x08)
        let b = try decodeStringIfPresent(tag: 0x12)
        let c = try decodeStringIfPresent(tag: 0x1a)
        let d = try decodeVarIntIfPresent(tag: 0x20)
        let e = try decodeVarIntIfPresent(tag: 0x28)
        let f = try decodeVarIntIfPresent(tag: 0x30)
        print("type: \(a, default: "nil"), \(b, default: "nil"), \(c, default: "nil"), \(d, default: "nil"), \(e, default: "nil"), \(f, default: "nil")")
    }
    
    mutating func decodeKey() throws(E) {
        let x = try decodeVarIntIfPresent(tag: 0x8) ?? 0
        let y = try decodeStringIfPresent(tag: 0x12)
        try assertAtEnd()
        print("key: \(x, default: "nil") \(y, default: "nil")")
    }
        
    mutating func decodeFieldTimestamp() throws(E) -> Date {
        let magic11 = try decodeVarInt()
        if magic11 != 0x11 {
            throw .invalidFormat("Unexpected field timestampt magic: \(magic11, hexWidth: 2))")
        }
        let ts = try decodeDouble()
        return Date(timeIntervalSinceReferenceDate: ts)
    }
    
    mutating func decodeFieldBackTrace(param: UInt) throws(E) -> [StackFrame] {
        let tag = 2+8*param
        var images: [ImageInfo] = []
        let frames = try decodeArray(tag: tag) { (d: inout TraceDecoder) throws(E) -> StackFrame in
            var child = try d.decodeChild()
            return try child.decodeStackFrame(images: &images)
        }
        return frames
    }
    
    mutating func decodeStackFrame(images: inout [ImageInfo]) throws(E) -> StackFrame {
        if let image = try decodeImageIfPresent() {
            print("image: #\(images.count) \(image.uuid) \(image.baseAddress, hexWidth: 16)..<\(image.baseAddress + image.size, hexWidth: 16) \(image.path)")
            images.append(image)
        }
        let index = try decodeVarIntIfPresent(tag: 0x8) ?? 0
        let offset = try decodeVarIntIfPresent(tag: 0x10) ?? 0
        try assertAtEnd()
        
        if index >= images.count {
            throw .invalidFormat("Stack frame refers to image not seen before")
        }
        
        let image = images[Int(index)]
        let frame = StackFrame(image: image, offset: offset)
        print("symbol: #\(index) \(offset, hexWidth: 16)")
        return frame
    }
    
    mutating func decodeImageIfPresent() throws(E) -> ImageInfo? {
        try decodeIfPresent(tag: 0x1a) { (d: inout TraceDecoder) throws(E) -> ImageInfo in
            var child = try d.decodeChild()
            return try child.decodeImage()
        }
    }
    
    mutating func decodeImage() throws(E) -> ImageInfo {
        guard let uuid = try decodeUUIDIfPresent(tag: 0x0a) else {
            throw .invalidFormat("UUID is required in ImageInfo")
        }
        let path = try decodeStringIfPresent(tag: 0x12) ?? ""
        let baseAddr = try decodeVarIntIfPresent(tag: 0x18) ?? 0
        let size = try decodeVarIntIfPresent(tag: 0x20) ?? 0
        return ImageInfo(uuid: uuid, path: path, baseAddress: baseAddr, size: size)
    }
    
    mutating func decodeUUIDIfPresent(tag: UInt) throws(E) -> UUID? {
        try decodeIfPresent(tag: tag) { (d: inout TraceDecoder) throws(E) -> UUID in
            try d.decodeUUID()
        }
    }
    
    mutating func decodeUUID() throws(E) -> UUID {
        let text = try decodeString()
        guard let UUID = UUID(uuidString: text) else {
            throw .invalidFormat("Invalid UUID format: \(text)")
        }
        return UUID
    }
    
    private mutating func decodeArray<T>(
        tag: UInt,
        block: (inout TraceDecoder) throws(E) -> T
    ) throws(E) -> [T] {
        var result: [T] = []
        while try decodeTag(tag) {
            let item = try block(&self)
            result.append(item)
        }
        return result
    }
    
    private mutating func decodeIfPresent<T>(
        tag: UInt,
        block: (inout TraceDecoder) throws(E) -> T
    ) throws(E) -> T? {
        if try decodeTag(tag) {
            return try block(&self)
        }
        return nil
    }
    
    private mutating func decodeVarIntIfPresent(tag: UInt) throws(E) -> UInt? {
        return try decodeIfPresent(tag: tag) { (d: inout TraceDecoder) throws(E) -> UInt in
            try d.decodeVarIntImpl()
        }
    }
    
    private mutating func decodeDataIfPresent(tag: UInt) throws(E) -> Data? {
        return try decodeIfPresent(tag: tag) { (d: inout TraceDecoder) throws(E) -> Data in
            try d.decodeLengthDelimited()
        }
    }
    
    private mutating func decodeStringIfPresent(tag: UInt) throws(E) -> String? {
        return try decodeIfPresent(tag: tag) { (d: inout TraceDecoder) throws(E) -> String in
            try d.decodeString()
        }
    }

    private mutating func decodeVarInt() throws(E) -> UInt {
        if let peekedTag {
            self.peekedTag = nil
            return peekedTag
        }
        return try decodeVarIntImpl()
    }
    
    private mutating func decodeVarIntImpl() throws(E) -> UInt {
        return try mappingError { () throws(DecoderError) -> UInt in
            try decoder.decodeVarInt()
        }
    }
    
    private mutating func decodeFixed64() throws(E) -> UInt64 {
        return try mappingError { () throws(DecoderError) -> UInt64 in
            try decoder.decodeFixed64()
        }
    }
    
    private mutating func decodeDouble() throws(E) -> Double {
        let bits = try decodeFixed64()
        return Double(bitPattern: bits)
    }
    
    private mutating func decodeLengthDelimited() throws(E) -> Data {
        return try mappingError { () throws(DecoderError) -> Data in
            try decoder.decodeLengthDelimited()
        }
    }
    
    private mutating func decodeString() throws(E) -> String {
        let data = try decodeLengthDelimited()
        guard let text = String(data: data, encoding: .utf8) else {
            throw .invalidFormat("Failed to decode string from data")
        }
        return text
    }
    
    private mutating func decodeChild() throws(E) -> TraceDecoder {
        let data = try decodeLengthDelimited()
        return TraceDecoder(data: data)
    }
        
    private func mappingError<T>( _ block: () throws(DecoderError) -> T) throws(E) -> T {
        do {
            return try block()
        } catch let e {
            switch e {
            case .eof: throw .eof
            }
        }
    }
    
    private func assertAtEnd() throws(E) {
        if !decoder.isAtEnd {
            throw .invalidFormat("Unexpected extra content")
        }
    }
    
    private mutating func skipTillEnd(_ context: String) {
        print("SKIP: \(context) <\(decoder.data.count - decoder.position) bytes>")
        decoder.position = decoder.data.count
    }
    
    private mutating func decodeTag(_ tag: UInt) throws(E) -> Bool {
        if try peekTag() == tag {
            self.peekedTag = nil
            return true
        }
        return false
    }
    
    private mutating func peekTag() throws(E) -> UInt? {
        if let peekedTag { return peekedTag }
        if decoder.isAtEnd { return nil }
        let result = try decodeVarIntImpl()
        peekedTag = result
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
