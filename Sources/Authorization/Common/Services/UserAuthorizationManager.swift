
import UIKit
import ReactiveKit
import DiiaCommonTypes
import DiiaCommonServices
import DiiaNetwork
import DiiaMVPModule

public protocol RefreshTemplateActionProvider {
    func refreshTemplateAction(with callback: @escaping Callback) -> (AlertTemplateAction) -> Void
}

public class UserAuthorizationManager: DisposeBagProvider, BindingExecutionContextProvider {
    // MARK: - Properties
    private weak var authorizationService: AuthorizationServiceProtocol?
    private let storage: AuthorizationStorageProtocol
    private let authStateHandler: AuthorizationServiceStateHandler
    private let refreshTemplateActionProvider: RefreshTemplateActionProvider
    private let userAuthorizationErrorRouter: RouterExtendedProtocol

    private(set) var token: String? {
        didSet {
            storage.saveAuthToken(token)
        }
    }
    var target: AuthTarget?
    var requestId: String?
    var processId: String?
    var flow: UserAuthorizationFlow = .login(completionHandler: { _, _ in })

    public var bindingExecutionContext: ExecutionContext { .immediateOnMain }
    public let bag: DisposeBag = DisposeBag()
    
    // MARK: - Init
    init(authorizationService: AuthorizationServiceProtocol,         storage: AuthorizationStorageProtocol,
         authStateHandler: AuthorizationServiceStateHandler,
         refreshTemplateActionProvider: RefreshTemplateActionProvider,
         userAuthorizationErrorRouter: RouterExtendedProtocol) {

        self.authorizationService = authorizationService
        self.storage = storage
        self.refreshTemplateActionProvider = refreshTemplateActionProvider
        self.authStateHandler = authStateHandler
        self.userAuthorizationErrorRouter = userAuthorizationErrorRouter

        self.token = storage.getAuthToken()

        guard let logoutToken: String = storage.getLogoutToken() else { return }
        
        if ReachabilityHelper.shared.isReachable() {
            logout(for: logoutToken)
        } else {
            ReachabilityHelper.shared.statusSignal
                .filter { $0 }
                .first()
                .observeNext { [weak self] _ in self?.logout(for: logoutToken) }
                .dispose(in: bag)
        }
    }

    convenience init(authorizationService: AuthorizationServiceProtocol,
                     network: AuthorizationNetworkContext,
                     storage: AuthorizationStorageProtocol,
                     authStateHandler: AuthorizationServiceStateHandler,
                     refreshTemplateActionProvider: RefreshTemplateActionProvider,
                     userAuthorizationErrorRouter: RouterExtendedProtocol) {
        self.init(authorizationService: authorizationService,
                  storage: storage,
                  authStateHandler: authStateHandler,
                  refreshTemplateActionProvider: refreshTemplateActionProvider,
                  userAuthorizationErrorRouter: userAuthorizationErrorRouter)
    }

    // MARK: - Public Methods
    func authorize(in view: BaseView? = nil, parameters: [String: String]? = nil, failureAction: Callback? = nil) {
        verify(in: view, parameters: parameters, failureAction: failureAction)
    }
    
    func loginWithToken(token: String, completion: Callback?) {
        processId = nil
        finishLogin(with: token, completion: completion)
    }

    func logout() {
        guard let logoutToken = token else { return }
        storage.saveLogoutToken(logoutToken)
        
        token = nil
        
        if ReachabilityHelper.shared.isReachable() {
            logout(for: logoutToken)
        } else {
            ReachabilityHelper.shared.statusSignal
                .filter { $0 }
                .first()
                .observeNext { [weak self] _ in self?.logout(for: logoutToken) }
                .dispose(in: bag)
        }
    }
    
    // MARK: - Private Methods
    private func verify(in view: BaseView? = nil, parameters: [String: String]? = nil, failureAction: Callback? = nil) {
        guard
            let target = target,
            let requestId = requestId,
            let processId = processId
        else {
            authorizationService?.isAuthorizingByDeeplink = false
            failureAction?()
            return
        }
        view?.showProgress()
        
    }
    
    func getToken(in view: BaseView? = nil, processId: String, completion: ((NetworkError?) -> Void)? = nil) {
        // TODO: Remove target from here
        guard
            let target = target
        else {
            completion?(.badUrl)
            return
        }
        view?.showProgress()
    }
    
    func prolongToken(in view: BaseView? = nil, processId: String, completion: ((NetworkError?) -> Void)? = nil) {
        view?.showProgress()
        
    }
    
    private func finishLogin(with token: String, completion: Callback?) {
        target = nil
        requestId = nil
        self.token = token
        self.authorizationService?.authState = .userAuth
        self.authorizationService?.userAuthSignal.receive()
        self.authStateHandler.onLoginDidFinish()
        completion?()
    }

    private func logout(for logoutToken: String) {
    }
}
