
import Foundation
import Alamofire
import DiiaMVPModule
import DiiaCommonTypes

public struct AuthorizationNetworkContext {
    public let session: Alamofire.Session
    public let host: String
    public let headers: [String: String]?

    public init(session: Alamofire.Session, host: String, headers: [String: String]?) {
        self.session = session
        self.host = host
        self.headers = headers
    }
}

public struct AuthorizationContext {
    let network: AuthorizationNetworkContext
    let storage: AuthorizationStorageProtocol
    let serviceAuthSuccessModule: BaseModule?
    let authStateHandler: AuthorizationServiceStateHandler

    public init(
        network: AuthorizationNetworkContext,
        storage: AuthorizationStorageProtocol,
        serviceAuthSuccessModule: BaseModule?,
        authStateHandler: AuthorizationServiceStateHandler,
    ) {
        self.network = network
        self.storage = storage
        self.serviceAuthSuccessModule = serviceAuthSuccessModule
        self.authStateHandler = authStateHandler
    }
}
