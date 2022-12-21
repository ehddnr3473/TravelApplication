//
//  TravelPlaner.swift
//  YeolmokTravel
//
//  Created by 김동욱 on 2022/12/20.
//

import Foundation
import Combine

/// Plan View Model
final class TravelPlaner: ObservableObject, PlanConfigurable, PlanTransfer {
    var model: MyTravelPlan
    
    let publisher = PassthroughSubject<Void, Never>()
    
    var planCount: Int {
        model.count
    }
    
    required init(_ model: MyTravelPlan) {
        self.model = model
    }
    
    func title(_ index: Int) -> String {
        model.title(index)
    }
    
    func date(_ index: Int) -> String {
        model.date(index)
    }
    
    func description(_ index: Int) -> String {
        model.description(index)
    }
    
    func writingHandler(_ data: some Plan, _ index: Int?) {
        guard let plan = data as? TravelPlan else { return }
        if let index = index {
            model.plans[index] = plan
            publisher.send()
        } else {
            model.appendPlan(plan)
            publisher.send()
        }
    }
    
    func setUpAddPlanView() -> WritingPlanViewController {
        let model = WritablePlan(TravelPlan(title: "", description: "", schedules: []))
        let writingPlanViewController = WritingPlanViewController()
        writingPlanViewController.model = model
        writingPlanViewController.writingStyle = WritingStyle.add
        writingPlanViewController.addDelegate = self
        writingPlanViewController.modalPresentationStyle = .fullScreen
        
        return writingPlanViewController
    }
    
    func setUpModifyPlanView(at index: Int) -> WritingPlanViewController {
        let model = WritablePlan(model.plans[index])
        let writingPlanViewController = WritingPlanViewController()
        writingPlanViewController.model = model
        writingPlanViewController.writingStyle = WritingStyle.edit
        writingPlanViewController.editDelegate = self
        writingPlanViewController.planListIndex = index
        writingPlanViewController.modalPresentationStyle = .fullScreen
        return writingPlanViewController
    }
}
