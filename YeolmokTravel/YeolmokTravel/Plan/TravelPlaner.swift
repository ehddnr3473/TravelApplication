//
//  TravelPlaner.swift
//  YeolmokTravel
//
//  Created by 김동욱 on 2022/12/20.
//

import Foundation

/// Plan View Model
final class TravelPlaner: PlanConfigurable, PlanTransfer {
    var model: MyTravelPlan
    
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
    
    func writingHandler(_ data: any Plan, _ index: Int?) {
        if let index = index {
            // edit plan
            
        } else {
            // add plan
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
