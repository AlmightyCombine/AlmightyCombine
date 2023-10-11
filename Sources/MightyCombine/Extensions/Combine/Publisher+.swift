//
//  Publisher+.swift
//
//
//  Created by 김인섭 on 10/10/23.
//

import Foundation
import Combine

public extension Publisher {
    
    var asyncThrows: Output {
        get async throws {
            try await withCheckedThrowingContinuation { continuation in
                var cancellable: AnyCancellable?
                var finishedWithoutValue = true
                cancellable = first()
                    .sink { completion in
                        switch completion {
                        case .finished:
                            if finishedWithoutValue {
                                continuation.resume(throwing: AnyPublisherError.finishedWithoutValue)
                            }
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    } receiveValue: { value in
                        finishedWithoutValue = false
                        continuation.resume(with: .success(value))
                    }
            }
        }
    }
    
    @available(macOS 10.15, *)
    func asyncMap<T>(_ transform: @escaping (Output) async -> T) -> Publishers.FlatMap<Future<T, Failure>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    let output = await transform(value)
                    promise(.success(output))
                }
            }
        }
    }
    
    @available(macOS 10.15, *)
    func asyncThrowsMap<T>(_ transform: @escaping (Output) async throws -> T) -> Publishers.FlatMap<Future<T, Error>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    do {
                        let output = try await transform(value)
                        promise(.success(output))
                    } catch let error {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}

enum AnyPublisherError: Error {
    case finishedWithoutValue
}
