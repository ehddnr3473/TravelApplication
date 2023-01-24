//
//  Memory.swift
//  YeolmokTravel
//
//  Created by 김동욱 on 2022/12/24.
//

import Foundation

/// Memory Model
struct Memory {
    let title: String
    let index: Int
    let uploadDate: Date
}

extension Memory {
    func toData() -> MemoryDTO {
        .init(
            title: title,
            index: index,
            uploadDate: uploadDate
        )
    }
}