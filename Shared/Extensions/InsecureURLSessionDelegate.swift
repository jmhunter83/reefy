//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import Logging
import Pulse

/// URLSession delegate that allows insecure connections (HTTP and self-signed certificates)
/// for local network servers when explicitly enabled.
final class InsecureURLSessionDelegate: URLSessionTaskDelegate {

    private let logger: NetworkLogger
    private let allowInsecureConnection: Bool

    init(logger: NetworkLogger, allowInsecureConnection: Bool) {
        self.logger = logger
        self.allowInsecureConnection = allowInsecureConnection
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only handle server trust challenges for HTTPS
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust
        else {
            // For other auth types, use default handling
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // If insecure connection is NOT allowed, use default handling
        guard allowInsecureConnection else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Log warning about insecure connection
        logger.logger.warning(
            "Accepting insecure SSL certificate for \(challenge.protectionSpace.host)",
            metadata: [
                "host": "\(challenge.protectionSpace.host)",
                "port": "\(challenge.protectionSpace.port)",
            ]
        )

        // Trust the server certificate without validation
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        // Forward to Pulse logger
        logger.logTaskCreated(task)
        completionHandler(request)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        // Forward to Pulse logger
        if let error {
            logger.logTask(task, didCompleteWithError: error)
        } else {
            logger.logTask(task, didCompleteWithError: nil)
        }
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        // Forward to Pulse logger
        logger.logDataTask(dataTask, didReceive: data)
    }
}
