//
//  Control.swift
//  YeolmokTravel
//
//  Created by 김동욱 on 2023/01/22.
//

import Foundation
import UIKit
import Combine

extension UIControl {
    func controlPublisher(for event: UIControl.Event) -> UIControl.EventPublisher {
        return UIControl.EventPublisher(control: self, event: event)
    }
    
    // Publisher
    struct EventPublisher: Publisher {
        typealias Output = UIControl
        typealias Failure = Never
        
        let control: UIControl
        let event: UIControl.Event
        
        func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, UIControl == S.Input {
            let subscription = EventSubscription(control: control, subscriber: subscriber, event: event)
            subscriber.receive(subscription: subscription)
        }
    }
    
    // Subscription
    fileprivate class EventSubscription<EventSubscriber: Subscriber>: Subscription where EventSubscriber.Input == UIControl, EventSubscriber.Failure == Never {

            let control: UIControl
            let event: UIControl.Event
            var subscriber: EventSubscriber?
            
            init(control: UIControl, subscriber: EventSubscriber, event: UIControl.Event) {
                self.control = control
                self.subscriber = subscriber
                self.event = event
                
                control.addTarget(self, action: #selector(eventDidOccur), for: event)
            }
            
            func request(_ demand: Subscribers.Demand) {}
            
            func cancel() {
                subscriber = nil
                control.removeTarget(self, action: #selector(eventDidOccur), for: event)
            }
            
            @objc func eventDidOccur() {
                _ = subscriber?.receive(control)
            }
        }
}