import Flutter
import UIKit
import bidscubeSdk

public class BidscubeSdkPlugin: NSObject, FlutterPlugin {
    private var registrar: FlutterPluginRegistrar?
    private var adDelegates: [String: FlutterAdDelegate] = [:]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "bidscube_sdk", binaryMessenger: registrar.messenger())
        let instance = BidscubeSdkPlugin()
        instance.registrar = registrar
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            let config = call.arguments as? [String: Any]
            initializeSDK(config: config, result: result)
        case "getImageAdView":
            let args = call.arguments as? [String: Any]
            let placementId = args?["placementId"] as? String
            getImageAdView(placementId: placementId, result: result)
        case "getVideoAdView":
            let args = call.arguments as? [String: Any]
            let placementId = args?["placementId"] as? String
            getVideoAdView(placementId: placementId, result: result)
        case "getNativeAdView":
            let args = call.arguments as? [String: Any]
            let placementId = args?["placementId"] as? String
            getNativeAdView(placementId: placementId, result: result)
        case "getBannerAdView":
            let args = call.arguments as? [String: Any]
            let placementId = args?["placementId"] as? String
            getBannerAdView(placementId: placementId, result: result)
        case "requestAd":
            let args = call.arguments as? [String: Any]
            let placementId = args?["placementId"] as? String
            let adType = args?["adType"] as? String
            let position = args?["position"] as? String
            requestAd(placementId: placementId, adType: adType, position: position, result: result)
        case "removeAdCallback":
            let args = call.arguments as? [String: Any]
            let placementId = args?["placementId"] as? String
            removeAdCallback(placementId: placementId, result: result)
        case "requestConsentInfoUpdate":
            requestConsentInfoUpdate(result: result)
        case "showConsentForm":
            showConsentForm(result: result)
        case "getSKAdNetworkIds":
            getSKAdNetworkIds(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initializeSDK(config: [String: Any]?, result: @escaping FlutterResult) {
        do {
            // Parse configuration from Flutter
            let baseURL = config?["baseURL"] as? String ?? "https://ssp-bcc-ads.com/sdk"
            let enableLogging = config?["enableLogging"] as? Bool ?? true
            let enableDebugMode = config?["enableDebugMode"] as? Bool ?? false
            let defaultAdTimeout = config?["defaultAdTimeout"] as? Int ?? 30000
            let enableTestMode = config?["enableTestMode"] as? Bool ?? false
            
            // Create SDK configuration using the native SDK
            let sdkConfig = SDKConfig.Builder()
                .baseURL(baseURL)
                .enableLogging(enableLogging)
                .enableDebugMode(enableDebugMode)
                .defaultAdTimeout(defaultAdTimeout)
                .build()
            
            // Initialize the native BidsCube SDK
            BidscubeSDK.initialize(config: sdkConfig)
            
            print("📱 [NATIVE] BidsCube SDK initialized successfully")
            result("Native iOS SDK initialized successfully with bidscubeSdk")
        } catch {
            print("📱 [NATIVE] Error initializing SDK: \(error)")
            result(FlutterError(code: "INITIALIZATION_ERROR", message: "Failed to initialize SDK: \(error.localizedDescription)", details: nil))
        }
    }

    private func getImageAdView(placementId: String?, result: @escaping FlutterResult) {
        do {
            guard let placementId = placementId else {
                result(FlutterError(code: "INVALID_PLACEMENT_ID", message: "Placement ID is required", details: nil))
                return
            }
            
            print("📱 [NATIVE] Creating Image Ad View using bidscubeSdk for placement: \(placementId)")
            
            // Create ad delegate for callbacks
            let adDelegate = FlutterAdDelegate()
            adDelegates["image_\(placementId)"] = adDelegate
            
            // Get image ad view from native SDK
            let imageAdView = BidscubeSDK.getImageAdView(placementId, adDelegate)
            
            print("📱 [NATIVE] Got native image ad view from bidscubeSdk")
            
            // Create a Flutter view factory to embed the native view
            let viewFactory = NativeAdViewFactory(adView: imageAdView)
            
            // Register the view factory with Flutter
            let registrar = self.registrar
            let viewId = "native_image_ad_view_\(placementId)"
            registrar?.register(viewFactory, withId: viewId)
            
            print("📱 [NATIVE] Registered view factory with ID: \(viewId)")
            print("📱 [NATIVE] Returning viewId to Flutter")
            
            result(["viewId": viewId])
        } catch {
            print("📱 [NATIVE] Error creating image ad view: \(error)")
            result(FlutterError(code: "IMAGE_AD_ERROR", message: "Failed to create image ad view: \(error.localizedDescription)", details: nil))
        }
    }

    private func getVideoAdView(placementId: String?, result: @escaping FlutterResult) {
        do {
            guard let placementId = placementId else {
                result(FlutterError(code: "INVALID_PLACEMENT_ID", message: "Placement ID is required", details: nil))
                return
            }
            
            print("📱 [NATIVE] Creating Video Ad View using bidscubeSdk for placement: \(placementId)")
            
            // Create ad delegate for callbacks
            let adDelegate = FlutterAdDelegate()
            adDelegates["video_\(placementId)"] = adDelegate
            
            // Get video ad view from native SDK
            let videoAdView = BidscubeSDK.getVideoAdView(placementId, adDelegate)
            
            print("📱 [NATIVE] Got native video ad view from bidscubeSdk")
            
            // Create a Flutter view factory to embed the native view
            let viewFactory = NativeAdViewFactory(adView: videoAdView)
            
            // Register the view factory with Flutter
            let registrar = self.registrar
            let viewId = "native_video_ad_view_\(placementId)"
            registrar?.register(viewFactory, withId: viewId)
            
            print("📱 [NATIVE] Registered view factory with ID: \(viewId)")
            result(["viewId": viewId])
        } catch {
            print("📱 [NATIVE] Error creating video ad view: \(error)")
            result(FlutterError(code: "VIDEO_AD_ERROR", message: "Failed to create video ad view: \(error.localizedDescription)", details: nil))
        }
    }

    private func getNativeAdView(placementId: String?, result: @escaping FlutterResult) {
        do {
            guard let placementId = placementId else {
                result(FlutterError(code: "INVALID_PLACEMENT_ID", message: "Placement ID is required", details: nil))
                return
            }
            
            print("📱 [NATIVE] Creating Native Ad View using bidscubeSdk for placement: \(placementId)")
            
            // Create ad delegate for callbacks
            let adDelegate = FlutterAdDelegate()
            adDelegates["native_\(placementId)"] = adDelegate
            
            // Get native ad view from native SDK
            let nativeAdView = BidscubeSDK.getNativeAdView(placementId, adDelegate)
            
            print("📱 [NATIVE] Got native ad view from bidscubeSdk")
            
            // Create a Flutter view factory to embed the native view
            let viewFactory = NativeAdViewFactory(adView: nativeAdView)
            
            // Register the view factory with Flutter
            let registrar = self.registrar
            let viewId = "native_native_ad_view_\(placementId)"
            registrar?.register(viewFactory, withId: viewId)
            
            print("📱 [NATIVE] Registered view factory with ID: \(viewId)")
            result(["viewId": viewId])
        } catch {
            print("📱 [NATIVE] Error creating native ad view: \(error)")
            result(FlutterError(code: "NATIVE_AD_ERROR", message: "Failed to create native ad view: \(error.localizedDescription)", details: nil))
        }
    }

    private func getBannerAdView(placementId: String?, result: @escaping FlutterResult) {
        do {
            // TODO: Create and return actual banner ad view
            // For now, return a placeholder
            result("BannerAdView created for placement: \(placementId ?? "unknown")")
        } catch {
            result(FlutterError(code: "BANNER_AD_ERROR", message: "Failed to create banner ad view: \(error.localizedDescription)", details: nil))
        }
    }

    private func requestAd(placementId: String?, adType: String?, position: String?, result: @escaping FlutterResult) {
        do {
            // TODO: Request actual ad
            // For now, just return success
            result("Ad requested for placement: \(placementId ?? "unknown"), type: \(adType ?? "unknown"), position: \(position ?? "unknown")")
        } catch {
            result(FlutterError(code: "REQUEST_AD_ERROR", message: "Failed to request ad: \(error.localizedDescription)", details: nil))
        }
    }

    private func removeAdCallback(placementId: String?, result: @escaping FlutterResult) {
        do {
            if let placementId = placementId {
                adDelegates.removeValue(forKey: "image_\(placementId)")
                adDelegates.removeValue(forKey: "video_\(placementId)")
                adDelegates.removeValue(forKey: "native_\(placementId)")
            }
            result("Ad callback removed for placement: \(placementId ?? "unknown")")
        } catch {
            result(FlutterError(code: "REMOVE_CALLBACK_ERROR", message: "Failed to remove ad callback: \(error.localizedDescription)", details: nil))
        }
    }

    private func requestConsentInfoUpdate(result: @escaping FlutterResult) {
        do {
            // TODO: Request actual consent info update
            // For now, just return success
            result("Consent info update requested")
        } catch {
            result(FlutterError(code: "CONSENT_INFO_ERROR", message: "Failed to request consent info update: \(error.localizedDescription)", details: nil))
        }
    }

    private func showConsentForm(result: @escaping FlutterResult) {
        do {
            // TODO: Show actual consent form
            // For now, just return success
            result("Consent form shown")
        } catch {
            result(FlutterError(code: "CONSENT_FORM_ERROR", message: "Failed to show consent form: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func getSKAdNetworkIds(result: @escaping FlutterResult) {
        do {
            let skAdNetworkIds = BidscubeSDK.getSKAdNetworkIDs()
            result(skAdNetworkIds)
        } catch {
            result(FlutterError(code: "SKADNETWORK_ERROR", message: "Failed to get SKAdNetwork IDs: \(error.localizedDescription)", details: nil))
        }
    }
}

// MARK: - Flutter View Factory
class NativeAdViewFactory: NSObject, FlutterPlatformViewFactory {
    private let adView: UIView
    
    init(adView: UIView) {
        self.adView = adView
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return NativeAdPlatformView(adView: adView, frame: frame)
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

// MARK: - Flutter Platform View
class NativeAdPlatformView: NSObject, FlutterPlatformView {
    private let adView: UIView
    private let frame: CGRect
    
    init(adView: UIView, frame: CGRect) {
        self.adView = adView
        self.frame = frame
    }
    
    func view() -> UIView {
        adView.frame = frame
        return adView
    }
}

// MARK: - Flutter Ad Delegate
class FlutterAdDelegate: NSObject, AdCallback {
    func onAdLoading(_ placementId: String) {
        print("📱 [NATIVE] Flutter Ad Loading: \(placementId)")
    }
    
    func onAdLoaded(_ placementId: String) {
        print("📱 [NATIVE] Flutter Ad Loaded: \(placementId)")
    }
    
    func onAdDisplayed(_ placementId: String) {
        print("📱 [NATIVE] Flutter Ad Displayed: \(placementId)")
    }
    
    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        print("📱 [NATIVE] Flutter Ad Failed: \(placementId) - \(errorMessage)")
    }
    
    func onAdClicked(_ placementId: String) {
        print("📱 [NATIVE] Flutter Ad Clicked: \(placementId)")
    }
    
    func onAdClosed(_ placementId: String) {
        print("📱 [NATIVE] Flutter Ad Closed: \(placementId)")
    }
    
    func onVideoAdStarted(_ placementId: String) {
        print("📱 [NATIVE] Flutter Video Ad Started: \(placementId)")
    }
    
    func onVideoAdCompleted(_ placementId: String) {
        print("📱 [NATIVE] Flutter Video Ad Completed: \(placementId)")
    }
    
    func onVideoAdSkipped(_ placementId: String) {
        print("📱 [NATIVE] Flutter Video Ad Skipped: \(placementId)")
    }
}
