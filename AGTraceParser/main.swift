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
        var traceDecoder = TraceDecoder(data: data)
        try traceDecoder.decodeAll()
    } catch {
        print(error)
    }
}

main()

