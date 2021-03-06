//
//  IconV.swift
//  SwiftIconV
//
//  Created by C.W. Betts on 12/14/15.
//  Copyright © 2015 C.W. Betts. All rights reserved.
//

import Swift

#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)

import Darwin.POSIX.iconv

#elseif os(Linux)

import Glibc
import SwiftGlibc.POSIX.iconv
import SwiftGlibc.C.errno

#endif

/// Swift wrapper around the iconv library functions

final public class IconV: CustomStringConvertible {
    var intIconv: iconv_t

    /// The string encoding that `convert` converts to
    public let toEncoding: String

    /// The string encoding that `convert` converts from
    public let fromEncoding: String

    public enum EncodingErrors: Error {
        /// The buffer is too small
        case BufferTooSmall
        /// Conversion function was passed `nil`
        case PassedNull
        /// The encoding name isn't recognized by libiconv
        case InvalidEncodingName
        /// Unable to convert from one encoding to another
        case InvalidMultibyteSequence
        /// Buffer ends between a multibyte sequence
        case IncompleteMultibyteSequence
        /// `errno` was an unknown value
        case UnknownError(Int32)
    }

    /// Initialize an IconV class that can convert one encoding to another
    /// - parameter fromEncoding: The name of the encoding to convert from
    /// - parameter toEncoding: The name of the encoding to convert to. Default is `"UTF-8"`
    /// - returns: an IconV class, or `nil` if an encoding name is invalid.
    public init?(fromEncoding: String, toEncoding: String = "UTF-8") {
        for char in fromEncoding.characters {
            if char == " " {
                return nil
            }
        }

        for char in toEncoding.characters {
            if char == " " {
                return nil
            }
        }

        self.fromEncoding = fromEncoding
        self.toEncoding = toEncoding
        intIconv = iconv_open(toEncoding, fromEncoding)
        if intIconv == nil {
            return nil
        }
    }

    /// Converts a pointer to a byte array from the encoding `fromEncoding` to `toEncoding`
    /// - parameter outBufferMax: the maximum size of the buffer to use. Default is `1024`.
    /// If passed `Int.max`, will attempt to convert the whole buffer without throwing `EncodingErrors.BufferTooSmall`.
    /// - parameter inBuf: A pointer to the buffer of bytes to convert. On return, will point to
    /// where the encoding ended.
    /// - parameter inBytes: the number of bytes in `inBuf`.
    /// - parameter outBuf: The converted bytes, appending the array.
    /// - returns: the number of non-reversible conversions performed.
    /// - throws: an `EncodingErrors` on failure, including the buffer size request being too small.
    ///
    /// If `outBufferMax` isn't large enough to store the converted characters,
    /// `EncodingErrors.BufferTooSmall` is thrown.<br>
    /// Even if the function throws, the converted bytes are added to `outBuf`.
    /// It is recommended to pass a copy of the pointer of the buffer and its length, as they are
    /// incremented internally.
    public func convert(inBuffer inBuf: inout UnsafeMutablePointer<Int8>?, inBytesCount inBytes: inout Int, outBuffer outBuf: inout [CChar], outBufferMax: Int = 1024) throws -> Int {
        if outBufferMax == Int.max {
            var icStatus = 0
            repeat {
                do {
                    icStatus += try convert(inBuffer: &inBuf, inBytesCount: &inBytes, outBuffer: &outBuf, outBufferMax: 2048)
                } catch let error as EncodingErrors {
                    switch error {
                    case .BufferTooSmall:
                        continue

                    default:
                        throw error
                    }
                }
            } while inBytes != 0
            return icStatus
        }
        let tmpBuf = UnsafeMutablePointer<Int8>.allocate(capacity: outBufferMax)
        defer {
            tmpBuf.deallocate(capacity: outBufferMax)
        }
        var tmpBufSize = outBufferMax
        var passedBuf: UnsafeMutablePointer<Int8>? = tmpBuf

        let iconvStatus = iconv(intIconv, &inBuf, &inBytes, &passedBuf, &tmpBufSize)
        let toAppend = UnsafeMutableBufferPointer(start: tmpBuf, count: outBufferMax - tmpBufSize)

        outBuf.append(contentsOf: toAppend)

        //failed
        if iconvStatus == -1 {
            switch errno {
            case EILSEQ:
                throw EncodingErrors.InvalidMultibyteSequence

            case E2BIG:
                throw EncodingErrors.BufferTooSmall

            case EINVAL:
                throw EncodingErrors.IncompleteMultibyteSequence

            default:
                throw EncodingErrors.UnknownError(errno)
            }
        }

        return iconvStatus
    }

    deinit {
        if intIconv != nil {
            iconv_close(intIconv)
        }
    }

    /// Resets the encoder to its default state
    public func reset() {
        iconv(intIconv, nil, nil, nil, nil)
    }

    public var description: String {
        return "From encoding: \"\(fromEncoding)\", to encoding \"\(toEncoding)\""
    }
}

#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
/// OS X-specific additions that may not be present on Linux.

extension IconV {
    private static var encodings = [[String]]()
    /// A list of all the available encodings.
    /// They are grouped so that names that reference the same encoding are in the same array
    /// within the returned array.

    /// Is `true` if the encoding conversion is trivial.
    public var trivial: Bool {
        var toRet: Int32 = 0
        iconvctl(intIconv, ICONV_TRIVIALP, &toRet)
        return toRet == 1
    }

    public var transliterates: Bool {
        get {
            var toRet: Int32 = 0
            iconvctl(intIconv, ICONV_GET_TRANSLITERATE, &toRet)
            return toRet == 1
        }
        set {
            var toRet: Int32
            if newValue {
                toRet = 1
            } else {
                toRet = 0
            }
            iconvctl(intIconv, ICONV_SET_TRANSLITERATE, &toRet)
        }
    }

    /// "illegal sequence discard and continue"
    public var discardIllegalSequence: Bool {
        get {
            var toRet: Int32 = 0
            iconvctl(intIconv, ICONV_GET_DISCARD_ILSEQ, &toRet)
            return toRet == 1
        }
        set {
            var toRet: Int32
            if newValue {
                toRet = 1
            } else {
                toRet = 0
            }
            iconvctl(intIconv, ICONV_SET_DISCARD_ILSEQ, &toRet)
        }
    }

    public func setHooks(hooks: iconv_hooks) {
        var tmpHooks = hooks
        iconvctl(intIconv, ICONV_SET_HOOKS, &tmpHooks)
    }

    public func setFallbacks(fallbacks: iconv_fallbacks) {
        var tmpHooks = fallbacks
        iconvctl(intIconv, ICONV_SET_FALLBACKS, &tmpHooks)
    }

    /// Canonicalize an encoding name.
    /// The result is either a canonical encoding name, or `name` itself.
    public class func canonicalizeEncoding(name: String) -> String {
        let retName = iconv_canonicalize(name)
        return String.init(cString: retName!)
    }
}

#endif

extension IconV.EncodingErrors: Equatable {

}

public func ==(lhs: IconV.EncodingErrors, rhs: IconV.EncodingErrors) -> Bool {
    switch (lhs, rhs) {
    case (.UnknownError(let lhsErr), .UnknownError(let rhsErr)):
        return lhsErr == rhsErr

    case (.BufferTooSmall, .BufferTooSmall):
        return true

    case (.PassedNull, .PassedNull):
        return true

    case (.InvalidEncodingName, .InvalidEncodingName):
        return true

    case (.InvalidMultibyteSequence, .InvalidMultibyteSequence):
        return true

    case (.IncompleteMultibyteSequence, .IncompleteMultibyteSequence):
        return true

    default:
        return false
    }
}

extension IconV {
    /// Converts a C string in the specified encoding to a Swift String.
    /// - parameter cstr: pointer to the C string to convert
    /// - parameter length: the length, in bytes, of `cstr`. If `nil`, uses `strlen` to get the length.
    /// Default value is `nil`.
    /// - parameter encName: the name of the encoding that the c string is in.
    /// - throws: an `EncodingErrors` on failure.
    ///
    /// Internally, this tells libiconv to convert the string to UTF-32,
    /// then initializes a Swift String from the result.
    @warn_unused_result public class func convertCString(cstr: UnsafePointer<Int8>, length: Int? = nil, fromEncodingNamed encName: String) throws -> String {
        if cstr == nil {
            throw EncodingErrors.PassedNull
        }

        //Use "UTF-32LE" so we don't have to worry about the BOM
        guard let converter = IconV(fromEncoding: encName, toEncoding: "UTF-32LE//IGNORE") else {
            throw EncodingErrors.InvalidEncodingName
        }

        let strLen = length ?? Int(strlen(cstr))
        var tmpStrLen = strLen
        var utf8Str = [Int8]()
        utf8Str.reserveCapacity(strLen * 4)
        var cStrPtr: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>(mutating: cstr)
        try converter.convert(inBuffer: &cStrPtr, inBytesCount: &tmpStrLen, outBuffer: &utf8Str, outBufferMax: Int.max)
        let preScalar: [UnicodeScalar] = {
            // Nasty, dirty hack to convert to [UInt32]
            let badPtr = UnsafeMutablePointer<Int8>(mutating: utf8Str)
            let rawGoodPtr = UnsafeRawPointer(badPtr)
            let goodPtr = rawGoodPtr.assumingMemoryBound(to: UInt32.self)
            let betterPtr = UnsafeBufferPointer(start: goodPtr, count: utf8Str.count / 4)

            // Make sure the UTF-32 number is in the processor's endian.
            return betterPtr.map({ UnicodeScalar($0.littleEndian)! })
        }()
        var scalar = String.UnicodeScalarView()
        scalar.append(contentsOf: preScalar)

        return String(scalar)
    }
}
