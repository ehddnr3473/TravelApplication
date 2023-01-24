//
//  TravelPlanDTO.swift
//  YeolmokTravel
//
//  Created by 김동욱 on 2023/01/24.
//

import Foundation

struct TravelPlanDTO {
    let title: String
    let description: String
    let schedules: [ScheduleDTO]
}

// MARK: - Mapping to domain
extension TravelPlanDTO {
    func toDomain() -> TravelPlan {
        let schedules = schedules.map { $0.toDomain() }
        return .init(
            title: title,
            description: description,
            schedules: schedules
        )
    }
}