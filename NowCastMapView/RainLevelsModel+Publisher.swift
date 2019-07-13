//
//  RainLevelsModel+Combine.swift
//  NowCastMapView iOS
//
//  Created by Hiroshi Noto on 2019/06/28.
//  Copyright © 2019 Hiroshi Noto. All rights reserved.
//

import Combine
import Foundation

@available(iOSApplicationExtension 13.0, *)
public extension RainLevelsModel {
    struct TaskPublisher: Publisher {
        public typealias Output = RainLevels
        public typealias Failure = Error
        let model: RainLevelsModel
        let request: RainLevelsModel.Request

        // This function is called to attach the specified Subscriber to this Publisher by subscribe(_:)
        public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            do {
                let task = try model.rainLevels(with: request) { result in
                    switch result {
                    case let .succeeded(_, rainLevels):
                        _ = subscriber.receive(rainLevels)
                        subscriber.receive(completion: .finished)

                    case let .failed(_, error):
                        subscriber.receive(completion: .failure(error))
                    }
                }

                let subscription = RequestSubscription(combineIdentifier: CombineIdentifier(), task: task)
                subscriber.receive(subscription: subscription)

                task.resume()
            } catch {
                subscriber.receive(completion: .failure(error))
            }
        }
    }

    struct RequestSubscription: Subscription {
        public let combineIdentifier: CombineIdentifier
        let task: RainLevelsModel.Task

        public func request(_ demand: Subscribers.Demand) {}

        public func cancel() {
            task.cancel()
        }
    }

    func publisher(for request: RainLevelsModel.Request) -> TaskPublisher {
        return TaskPublisher(model: self, request: request)
    }
}
