// SHA-1 implementation in Swift 4
// $AUTHOR: Iggy Drougge
// $VER: 2.3.1

import Foundation

/// Left rotation (or cyclic shift) operator
infix operator <<< : BitwiseShiftPrecedence
private func <<< (lhs:UInt32, rhs:UInt32) -> UInt32 {
    return lhs << rhs | lhs >> (32-rhs)
}

public struct SHA1 {
    // One chunk consists of 80 big-endian longwords (32 bits, unsigned)
    private static let CHUNKSIZE=80
    // SHA-1 magic words
    private static let h0: UInt32 = 0x67452301
    private static let h1: UInt32 = 0xEFCDAB89
    private static let h2: UInt32 = 0x98BADCFE
    private static let h3: UInt32 = 0x10325476
    private static let h4: UInt32 = 0xC3D2E1F0
    
        // Initialise variables:
//        private var h:[UInt32]=[SHA1.h0,SHA1.h1,SHA1.h2,SHA1.h3,SHA1.h4]
    private(set) var h = (SHA1.h0, SHA1.h1, SHA1.h2, SHA1.h3, SHA1.h4)
        
    // Process one chunk of 80 big-endian longwords
    mutating internal func process(chunk: inout ContiguousArray<UInt32>) {
        for i in 0..<16 {
            chunk[i] = chunk[i].bigEndian // The numbers must be big-endian
        }
        //chunk=chunk.map{$0.bigEndian}   // The numbers must be big-endian
        for i in 16...79 {                // Extend the chunk to 80 longwords
            chunk[i] = (chunk[i-3] ^ chunk[i-8] ^ chunk[i-14] ^ chunk[i-16]) <<< 1
        }
        
        // Initialise hash value for this chunk:
        var a = h.0, b = h.1, c = h.2, d = h.3, e = h.4
        var f: UInt32 = 0, k: UInt32 = 0
        var temp: UInt32
        
        // Main loop
        for i in 0...79 {
            switch i {
            case 0...19:
                f = (b & c) | ((~b) & d)
                k = 0x5A827999
            case 20...39:
                f = b ^ c ^ d
                k = 0x6ED9EBA1
            case 40...59:
                f = (b & c) | (b & d) | (c & d)
                k = 0x8F1BBCDC
            case 60...79:
                f = b ^ c ^ d
                k = 0xCA62C1D6
            default: break
            }
            temp = a <<< 5 &+ f &+ e &+ k &+ chunk[i]
            e = d
            d = c
            c = b <<< 30
            b = a
            a = temp
            //print(String(format: "t=%d %08X %08X %08X %08X %08X", i, a, b, c, d, e))
        }
        
        // Add this chunk's hash to result so far:
        h.0 = h.0 &+ a
        h.1 = h.1 &+ b
        h.2 = h.2 &+ c
        h.3 = h.3 &+ d
        h.4 = h.4 &+ e
    }

    public init(from data: inout Data){
        var w = ContiguousArray<UInt32>(repeating: 0x00000000, count: Self.CHUNKSIZE) // Initialise empty chunk
        let ml = data.count << 3                                        // Message length in bits
        var range = 0..<64                                            // A chunk is 64 bytes
        
        // If the remainder of the message is more than or equal 64 bytes
        while data.count >= range.upperBound {
            //print("Reading \(range.count) bytes @ position \(range.lowerBound)")
            w.withUnsafeMutableBufferPointer{ dest in
                data.copyBytes(to: dest, from: range)               // Retrieve one chunk
            }
            process(chunk: &w)                                // Process the chunk
            range = range.upperBound..<range.upperBound+64            // Make range for next chunk
        }
        
        // Handle remainder of message that is <64 bytes in length
        w = ContiguousArray<UInt32>(repeating: 0x00000000, count: Self.CHUNKSIZE) // Initialise empty chunk
        range = range.lowerBound..<data.count                         // Range for remainder of message
        w.withUnsafeMutableBufferPointer{ dest in
            data.copyBytes(to: dest, from: range)                   // Retrieve remainder
        }
        let bytetochange=range.count % 4                              // The bit to the right of the
        let shift = UInt32(bytetochange * 8)                          // last bit of the actual message
        w[range.count/4] |= 0x80 << shift                             // should be set to 1.
        // If the remainder overflows, a new, empty chunk must be added
        if range.count+1 > 56 {
            process(chunk: &w)
            w = ContiguousArray<UInt32>(repeating: 0x00000000, count: Self.CHUNKSIZE)
        }
        
        // The last 64 bits of the last chunk must contain the message length in big-endian format
        w[15] = UInt32(ml).bigEndian
        process(chunk: &w)                                    // Process the last chunk
        
        // The context (or nil) is returned, containing the hash in the h[] array
    }
    
    public var hex: String {
        String(format: "%08x%08x%08x%08x%08x", h.0, h.1, h.2, h.3, h.4)
    }
    
    public var data: Data {
        var data = Data(count: 20)
        data[(0<<2) | 0] = UInt8((h.0 >> 24) & 0xFF)
        data[(0<<2) | 1] = UInt8((h.0 >> 16) & 0xFF)
        data[(0<<2) | 2] = UInt8((h.0 >> 8) & 0xFF)
        data[(0<<2) | 3] = UInt8((h.0) & 0xFF)

        data[(1<<2) | 0] = UInt8((h.1 >> 24) & 0xFF)
        data[(1<<2) | 1] = UInt8((h.1 >> 16) & 0xFF)
        data[(1<<2) | 2] = UInt8((h.1 >> 8) & 0xFF)
        data[(1<<2) | 3] = UInt8((h.1) & 0xFF)

        data[(2<<2) | 0] = UInt8((h.2 >> 24) & 0xFF)
        data[(2<<2) | 1] = UInt8((h.2 >> 16) & 0xFF)
        data[(2<<2) | 2] = UInt8((h.2 >> 8) & 0xFF)
        data[(2<<2) | 3] = UInt8((h.2) & 0xFF)

        data[(3<<2) | 0] = UInt8((h.3 >> 24) & 0xFF)
        data[(3<<2) | 1] = UInt8((h.3 >> 16) & 0xFF)
        data[(3<<2) | 2] = UInt8((h.3 >> 8) & 0xFF)
        data[(3<<2) | 3] = UInt8((h.3) & 0xFF)

        data[(4<<2) | 0] = UInt8((h.4 >> 24) & 0xFF)
        data[(4<<2) | 1] = UInt8((h.4 >> 16) & 0xFF)
        data[(4<<2) | 2] = UInt8((h.4 >> 8) & 0xFF)
        data[(4<<2) | 3] = UInt8((h.4) & 0xFF)
        
        return data
    }
}
