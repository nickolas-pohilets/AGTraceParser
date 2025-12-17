//
//  main.swift
//  AGTraceParser
//
//  Created by Nickolas Pokhylets on 16/12/2025.
//

import Foundation

func main()  {
    do {
        let data = try Data(contentsOf: URL(filePath: "/Users/npohilets/Desktop/trace-0001.ag-trace"))
        var traceDecoder = TraceDecoder(decoder: Decoder(data: data))
        try traceDecoder.decodeAll()
        print("Done!")
    } catch {
        print(error)
    }
}

main()

