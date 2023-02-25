//
//  WritingMemoryViewModel.swift
//  YeolmokTravel
//
//  Created by 김동욱 on 2023/01/22.
//

import Foundation
import UIKit
import Combine
import Domain

private protocol WritingMemoryViewModel: AnyObject {
    associatedtype Input
    associatedtype Output
    
    func upload(_ index: Int, _ image: UIImage, _ memory: Memory) async throws
    func transform(input: Input) -> Output
}

final class DefaultWritingMemoryViewModel: WritingMemoryViewModel {
    private let memoriesUseCaseProvider: MemoriesUseCaseProvider
    private let imagesUseCaseProvider: ImagesUseCaseProvider
    
    // MARK: - Init
    init(_ memoriesUseCaseProvider: MemoriesUseCaseProvider, _ imagesUseCaseProvider: ImagesUseCaseProvider) {
        self.memoriesUseCaseProvider = memoriesUseCaseProvider
        self.imagesUseCaseProvider = imagesUseCaseProvider
    }
    
    func upload(_ index: Int, _ image: UIImage, _ memory: Memory) async throws {
        let uploadMemoryUseCase = memoriesUseCaseProvider.provideUploadMemoryUseCase()
        try await uploadMemoryUseCase.execute(at: index, memory)
        
        let uploadImageUseCase = imagesUseCaseProvider.provideUploadImageUseCase()
        try await uploadImageUseCase.execute(at: index, image)
    }
}

extension DefaultWritingMemoryViewModel {
    struct Input {
        let title: AnyPublisher<String, Never>
        let image: AnyPublisher<Bool, Never>
    }
    
    struct Output {
        let buttonState: AnyPublisher<Bool, Never>
    }
    
    func transform(input: Input) -> Output {
        let buttonStatePublisher = input.title.combineLatest(input.image)
            .map { title, image in
                title.count > 0 && image
            }
            .eraseToAnyPublisher()
        
        return Output(buttonState: buttonStatePublisher)
    }
}
