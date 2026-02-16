//
//import UIKit
//import ReactiveKit
//import DiiaMVPModule
//import DiiaCommonTypes
//import DiiaCommonServices
//
//class ServiceAuthorizationManager {
//    
//    // MARK: - Properties
//    private weak var authorizationService: AuthorizationServiceProtocol?
//    private let storage: AuthorizationStorageProtocol
//    private let mobileUID: () -> String
//    private let authSuccessModule: BaseModule?
//    private let userAuthorizationErrorRouter: RouterProtocol
//
//    private let disposeBag = DisposeBag()
//
//    private(set) var serviceToken: String? {
//        didSet {
//            storage.saveServiceToken(serviceToken)
//        }
//    }
//    
//    // MARK: - Init
//    init(authorizationService: AuthorizationServiceProtocol,
//         storage: AuthorizationStorageProtocol,
//         mobileUID: @escaping () -> String,
//         authSuccessModule: BaseModule?,
//         userAuthorizationErrorRouter: RouterProtocol) {
//        self.authorizationService = authorizationService
//        self.storage = storage
//        self.mobileUID = mobileUID
//        self.authSuccessModule = authSuccessModule
//        self.userAuthorizationErrorRouter = userAuthorizationErrorRouter
//
//        serviceToken = storage.getServiceToken()
//    }
//
//    convenience init(authorizationService: AuthorizationServiceProtocol,
//                     storage: AuthorizationStorageProtocol,
//                     networkContext: AuthorizationNetworkContext,
//                     mobileUID: @escaping () -> String,
//                     authSuccessModule: BaseModule?,
//                     userAuthorizationErrorRouter: RouterProtocol) {
//        self.init(authorizationService: authorizationService,
//                  storage: storage,
//                  mobileUID: mobileUID,
//                  authSuccessModule: authSuccessModule,
//                  userAuthorizationErrorRouter: userAuthorizationErrorRouter)
//    }
//
//    // MARK: - Public Methods
//    func logout() {
//        guard let logoutToken = serviceToken else { return }
//        storage.saveServiceLogoutToken(logoutToken)
//        
//        serviceToken = nil
//        
//        if ReachabilityHelper.shared.isReachable() {
//            logout(for: logoutToken)
//        } else {
//            ReachabilityHelper.shared.statusSignal
//                .filter { $0 }
//                .first()
//                .observeNext { _ in self.logout(for: logoutToken) }
//                .dispose(in: disposeBag)
//        }
//    }
//    
//    func refresh(completion: ((Error?) -> Void)? = nil) {
//        serviceEntranceClient?
//            .refresh(token: authorizationService?.token ?? "")
//            .observe { signal in
//                switch signal {
//                case .completed:
//                    break
//                case .next(let response):
//                    self.serviceToken = response.token
//                    completion?(nil)
//                case .failed(let error):
//                    switch error {
//                    case .nsUrlErrorDomain(_, let statusCode), .wrongStatusCode(_, let statusCode, _):
//                        if statusCode == 401 {
//                            self.authorizationService?.logout()
//                        }
//                    default:
//                        break
//                    }
//                    
//                    completion?(error)
//                }
//            }
//            .dispose(in: disposeBag)
//    }
//    
//    // MARK: - Private Methods
//    private func logout(for logoutToken: String) {
//        let uid = mobileUID()
//        serviceEntranceClient?
//            .logout(token: logoutToken, mobileUid: uid)
//            .observe { _ in self.storage.removeServiceLogoutToken() }
//            .dispose(in: disposeBag)
//    }
//}
