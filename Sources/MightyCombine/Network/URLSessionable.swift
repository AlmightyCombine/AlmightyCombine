//
//  URLSessionable.swift
//  
//
//  Created by 김인섭 on 10/5/23.
//

import Foundation
import Combine

public protocol URLSessionable {
    
    static var printLog: Bool { get }
    static var requestLogStyle: LogStyle { get }
    static var responseLogStyle: LogStyle { get }
    
    @available(macOS 10.15, *)
    func requestPublisher<T: Decodable>(
        _ urlRequest: URLRequest,
        expect: T.Type?,
        requestLogStyle: LogStyle,
        responseLogStyle: LogStyle,
        scheduler: DispatchQueue,
        responseHandler: ((_ response: HTTPURLResponse) throws -> Void)?
    ) -> AnyPublisher<T, Error>
    
    @available(macOS 10.15, *)
    func uploadPublisher<T: Decodable>(
        for request: URLRequest,
        from bodyData: Data,
        expect: T.Type?,
        requestLogStyle: LogStyle,
        responseLogStyle: LogStyle,
        scheduler: DispatchQueue,
        responseHandler: ((_ response: HTTPURLResponse) throws -> Void)?
    ) -> AnyPublisher<T, Error>
}

public extension URLSessionable {
    
    func printRequestLog(_ request: URLRequest, logStyle: LogStyle) {
        #if DEBUG
        guard Self.printLog else { return }
        var body: Any?
        if let data = request.httpBody {
            switch logStyle {
            case .json:
                body = try? JSONSerialization.jsonObject(with: data)
            case .string:
                body = String(data: data, encoding: .utf8)
            case .none:
                body = nil
            }
        }
        let log = """
        🛫 Network Request Log
            - absoluteURL: \(request.url?.absoluteString ?? "")
            - header: \(request.allHTTPHeaderFields ?? [:])
            - method: \(request.httpMethod ?? "")
            - body: \(body ?? "")
        """
        print(log)
        #endif
    }
    
    func printResponseLog(_ response: HTTPURLResponse, data: Data?, logStyle: LogStyle) {
        #if DEBUG
        guard Self.printLog else { return }
        var body: Any?
        if let data = data {
            switch logStyle {
            case .json:
                body = try? JSONSerialization.jsonObject(with: data)
            case .string:
                body = String(data: data, encoding: .utf8)
            case .none:
                body = nil
            }
        }
        let log = """
        🛬 Network Response Log
            - absoluteURL: \(response.url?.absoluteString ?? "")
            - statusCode: \(response.statusCode)
            - data: \(body ?? "")
        """
        print(log)
        #endif
    }
    
    @available(macOS 10.15, *)
    func requestPublisher<T: Decodable>(
        _ urlRequest: URLRequest,
        expect: T.Type? = nil,
        requestLogStyle: LogStyle = Self.requestLogStyle,
        responseLogStyle: LogStyle = Self.responseLogStyle,
        scheduler: DispatchQueue = .main,
        responseHandler: ((_ response: HTTPURLResponse) throws -> Void)? = nil
    ) -> AnyPublisher<T, Error> {
        requestPublisher(
            urlRequest,
            expect: expect,
            requestLogStyle: requestLogStyle,
            responseLogStyle: responseLogStyle,
            scheduler: scheduler,
            responseHandler: responseHandler
        )
    }
    
    @available(macOS 10.15, *)
    func uploadPublisher<T: Decodable>(
        for request: URLRequest,
        from bodyData: Data,
        expect: T.Type? = nil,
        requestLogStyle: LogStyle = Self.requestLogStyle,
        responseLogStyle: LogStyle = Self.responseLogStyle,
        scheduler: DispatchQueue = .main,
        responseHandler: ((_ response: HTTPURLResponse) throws -> Void)? = nil
    ) -> AnyPublisher<T, Error> {
        uploadPublisher(
            for: request,
            from: bodyData,
            expect: expect,
            requestLogStyle: requestLogStyle,
            responseLogStyle: responseLogStyle,
            scheduler: scheduler,
            responseHandler: responseHandler
        )
    }
}

public enum LogStyle {
    case json, string, none
}
