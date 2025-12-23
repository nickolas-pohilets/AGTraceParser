//
//  main.swift
//  AGTraceParser
//
//  Created by Nickolas Pokhylets on 16/12/2025.
//

import Foundation

func main()  {
    do {
        let data = try Data(contentsOf: URL(filePath: CommandLine.arguments[1]))
        var traceDecoder = TraceDecoder(data: data, nsTracker: nil)
        try traceDecoder.decodeAll()
        traceDecoder.nsTracker.analyze()
    } catch {
        print(error)
    }
}

main()

