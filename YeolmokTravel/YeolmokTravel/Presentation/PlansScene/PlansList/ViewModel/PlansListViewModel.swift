//
//  PlansListViewModel.swift
//  YeolmokTravel
//
//  Created by 김동욱 on 2022/12/20.
//

import Foundation
import Combine
import Domain
import FirebasePlatform
import CoreLocation

protocol PlansListViewModelInput {
    func upload(_ plan: Plan) throws
    func delete(at index: Int) async throws
}

protocol PlansListViewModelOutput {
    var plans: CurrentValueSubject<[Plan], Never> { get }
    func read() async throws // viewDidLoad
    func getDateString(at index: Int) -> String
    func getCoordinates(at index: Int) -> [CLLocationCoordinate2D]
}

protocol PlansListViewModel: PlansListViewModelInput, PlansListViewModelOutput, AnyObject {}

final class DefaultPlansListViewModel: PlansListViewModel {
    private let useCaseProvider: PlansUseCaseProvider
    // MARK: - Output
    let plans = CurrentValueSubject<[Plan], Never>([])
    
    // MARK: - Init
    init(_ useCaseProvider: PlansUseCaseProvider) {
        self.useCaseProvider = useCaseProvider
    }
    
    func read() async throws {
        let readUseCase = useCaseProvider.provideReadPlansUseCase()
        plans.send(try await readUseCase.execute())
    }
    
    func getDateString(at index: Int) -> String {
        if let fromDate = plans.value[index].schedules.compactMap({ $0.fromDate }).min(),
           let toDate = plans.value[index].schedules.compactMap({ $0.toDate }).max() {
            let slicedFromDate = DateConverter.dateToString(fromDate)
            let slicedToDate = DateConverter.dateToString(toDate)
            if slicedFromDate == slicedToDate {
                return slicedFromDate
            } else {
                return "\(slicedFromDate) ~ \(slicedToDate)"
            }
        } else {
            return DateConverter.Constants.nilDateText
        }
    }
    
    func getCoordinates(at index: Int) -> [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        for schedule in plans.value[index].schedules {
            coordinates.append(schedule.coordinate)
        }
        return coordinates
    }
}

// MARK: - Input
extension DefaultPlansListViewModel {
    func upload(_ plan: Plan) throws {
        let uploadUseCase = useCaseProvider.provideUploadPlanUseCase()
        try uploadUseCase.execute(plan: plan)
        plans.value.append(plan)
    }
    
    func delete(at index: Int) async throws {
        let deleteUseCase = useCaseProvider.provideDeletePlanUseCase()
        try await deleteUseCase.execute(key: String(index))
        plans.value.remove(at: index)
    }
}
