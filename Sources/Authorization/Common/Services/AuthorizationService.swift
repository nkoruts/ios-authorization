
import UIKit
import ReactiveKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaNetwork

public protocol AuthorizationServiceProtocol: AnyObject, Logoutable {
    var authState: AuthorizationState { get set }

    var isAuthorizingByDeeplink: Bool { get set }
}

public protocol PinCodeManagerProtocol: AnyObject {
    func havePincode() -> Bool
    func setPincode(pincode: [Int])
    func checkPincode(pincode: [Int]) -> Bool
    func doesNeedPincode() -> Bool
}

public protocol Logoutable: AnyObject {
    func logout()
}
                                        
public protocol UserAuthFlowHandlerProtocol: AnyObject {
    func setUserAuthorizationFlow(_ flow: UserAuthorizationFlow)
}

public protocol AuthorizationServiceStateHandler {
    func onLoginDidFinish()
    func onLogoutDidFinish()
}

// MARK: - AuthorizationService
public final class AuthorizationService: AuthorizationServiceProtocol {

    // MARK: - Properties
    private let context: AuthorizationContext

    private var hashedPincode: String? {
        didSet {
            context.storage.saveHashedPincode(hashedPincode)
        }
    }
    
    private var token: String? {
        didSet {
            context.storage.saveAuthToken(token)
        }
    }
    
    public lazy var authState: AuthorizationState = {
        guard token != nil else { return .notAuthorized }
        return .userAuth
    }()
    
    public let userAuthSignal = PassthroughSubject<Void, Never>()
    public var isAuthorizingByDeeplink = false

    // MARK: - Public Init
    public init(context: AuthorizationContext) {
        self.context = context

        hashedPincode = context.storage.getHashedPincode()
        token = context.storage.getAuthToken()
    }
    
    public func isAuthorized() -> Bool {
        authState != .notAuthorized
    }
}

extension AuthorizationService: Logoutable {
    public func logout() {
        hashedPincode = nil
        authState = .notAuthorized

        context.authStateHandler.onLogoutDidFinish()
        
        guard let token else { return }
        context.storage.saveLogoutToken(token)
        self.token = nil
    }
}

extension AuthorizationService: PinCodeManagerProtocol {
    public func havePincode() -> Bool {
        return hashedPincode != nil
    }
    
    public func setPincode(pincode: [Int]) {
        self.hashedPincode = pincode.map { String($0) }.joined().toSHA256()
    }
    
    public func checkPincode(pincode: [Int]) -> Bool {
        return self.hashedPincode == pincode.map { String($0) }.joined().toSHA256()
    }
    
    public func doesNeedPincode() -> Bool {
        if !isAuthorized() || !havePincode() { return false }
        
        if let date: Date = context.storage.getLastPincodeDate() {
            return Date() - date >= Constants.timeForNeedPincode
        }
        return true
    }
}


// MARK: - Constants
extension AuthorizationService {
    private enum Constants {
        static let timeForNeedPincode: Double = 300
    }
}
