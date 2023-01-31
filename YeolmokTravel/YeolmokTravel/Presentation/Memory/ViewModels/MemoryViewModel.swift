//
//  MemoryViewModel.swift
//  YeolmokTravel
//
//  Created by 김동욱 on 2023/01/24.
//

import Foundation
import Combine

final class MemoryViewModel {
    private let useCase: ModelControlUsable
    let reloadPublisher = PassthroughSubject<Void, Never>()
    
    var count: Int {
        useCase.count
    }
    
    init(_ useCase: ModelControlUsable) {
        self.useCase = useCase
    }
    
    func memory(_ index: Int) -> Memory {
        useCase.query(index) as! Memory
    }
    
    func add(_ memory: Memory) {
        useCase.add(memory)
        reloadPublisher.send()
    }
}
