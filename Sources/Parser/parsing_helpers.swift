//
//  File.swift
//  
//
//  Created by Donald Pinckney on 11/25/19.
//

import Foundation

func impossible() -> Never {
    fatalError("ERROR: This case should be impossible")
}

func unimplemented(function: String = #function) -> Never {
    fatalError("Not yet implemented: \(function)")
}
