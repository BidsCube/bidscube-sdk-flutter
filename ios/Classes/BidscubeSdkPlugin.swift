import Flutter
import UIKit
import bidscubeSdk

public class BidscubeSdkPlugin: NSObject, FlutterPlugin {
    private var registrar: FlutterPluginRegistrar?
    private var channel: FlutterMethodChannel?

    /// Retain native delegates for in-flight placements.
    private var adDelegates: [String: FlutterAdDelegate] = [:]

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "bidscube_sdk", binaryMessenger: registrar.messenger())
        let instance = BidscubeSdkPlugin()
        instance.registrar = registrar
        instance.channel = channel
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
        case "getVideoAdView", "getInterstitialVideoAdView":
            let args = call.arguments as? [String: Any]
            let placementId = args?["placementId"] as? String
            getInterstitialVideoAdView(placementId: placementId, result: result)
        case "getRewardedVideoAdView":
            let args = call.arguments as? [String: Any]
            let placementId = args?["placementId"] as? String
            getRewardedVideoAdView(placementId: placementId, result: result)
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

            let sdkConfig = SDKConfig.Builder()
                .baseURL(baseURL)
                .enableLogging(enableLogging)
                .enableDebugMode(enableDebugMode)
                .defaultAdTimeout(defaultAdTimeout)
                .build()

            BidscubeSDK.initialize(config: sdkConfig)

            print("📱 [NATIVE] BidsCube SDK initialized successfully")
            result("Native iOS SDK initialized successfully with bidscubeSdk")
        } catch {
            print("📱 [NATIVE] Error initializing SDK: \(error)")
            result(
                FlutterError(
                    code: "INITIALIZATION_ERROR",
                    message: "Failed to initialize SDK: \(error.localizedDescription)",
                    details: nil
                ))
        }
    }

    private func getImageAdView(placementId: String?, result: @escaping FlutterResult) {
        do {
            guard let placementId = placementId else {
                result(
                    FlutterError(code: "INVALID_PLACEMENT_ID", message: "Placement ID is required", details: nil))
                return
            }
            guard let ch = channel else {
                result(FlutterError(code: "NO_CHANNEL", message: "Method channel unavailable", details: nil))
                return
            }
            guard let registrar = self.registrar else {
                result(FlutterError(code: "NO_REGISTRAR", message: "Plugin registrar unavailable", details: nil))
                return
            }

            print("📱 [NATIVE] Creating Image Ad View using bidscubeSdk for placement: \(placementId)")

            let adDelegate = FlutterAdDelegate(channel: ch)
            adDelegates["image_\(placementId)"] = adDelegate

            let imageAdView = BidscubeSDK.getImageAdView(placementId, adDelegate)

            let viewId = "native_image_ad_view_\(placementId)"
            registrar.register(NativeAdViewFactory(adView: imageAdView), withId: viewId)

            result(["viewId": viewId])
        } catch {
            print("📱 [NATIVE] Error creating image ad view: \(error)")
            result(
                FlutterError(
                    code: "IMAGE_AD_ERROR",
                    message: "Failed to create image ad view: \(error.localizedDescription)",
                    details: nil
                ))
        }
    }

    private func getInterstitialVideoAdView(placementId: String?, result: @escaping FlutterResult) {
        attachVideo(format: .interstitial, placementId: placementId, factoryPrefix: "native_interstitial_video", delegateKeyPrefix: "video", result: result)
    }

    private func getRewardedVideoAdView(placementId: String?, result: @escaping FlutterResult) {
        attachVideo(format: .rewarded, placementId: placementId, factoryPrefix: "native_rewarded_video", delegateKeyPrefix: "rewarded", result: result)
    }

    private func attachVideo(
        format: VideoAdFormat,
        placementId: String?,
        factoryPrefix: String,
        delegateKeyPrefix: String,
        result: @escaping FlutterResult
    ) {
        do {
            guard let placementId = placementId else {
                result(
                    FlutterError(code: "INVALID_PLACEMENT_ID", message: "Placement ID is required", details: nil))
                return
            }
            guard let ch = channel else {
                result(FlutterError(code: "NO_CHANNEL", message: "Method channel unavailable", details: nil))
                return
            }
            guard let registrar = self.registrar else {
                result(FlutterError(code: "NO_REGISTRAR", message: "Plugin registrar unavailable", details: nil))
                return
            }

            print(
                "📱 [NATIVE] Creating \(format == .rewarded ? "Rewarded" : "Interstitial") Video Ad View for \(placementId)")

            let adDelegate = FlutterAdDelegate(channel: ch)
            adDelegates["\(delegateKeyPrefix)_\(placementId)"] = adDelegate

            let videoAdView: UIView
            switch format {
            case .interstitial:
                videoAdView = BidscubeSDK.getInterstitialVideoAdView(placementId, adDelegate)
            case .rewarded:
                videoAdView = BidscubeSDK.getRewardedVideoAdView(placementId, adDelegate)
            }

            let viewId = "\(factoryPrefix)_ad_view_\(placementId)"
            registrar.register(NativeAdViewFactory(adView: videoAdView), withId: viewId)

            result(["viewId": viewId])
        } catch {
            print("📱 [NATIVE] Error creating \(format) video ad view: \(error)")
            result(
                FlutterError(
                    code: "VIDEO_AD_ERROR",
                    message: "Failed to create video ad view: \(error.localizedDescription)",
                    details: nil
                ))
        }
    }

    private func getNativeAdView(placementId: String?, result: @escaping FlutterResult) {
        do {
            guard let placementId = placementId else {
                result(
                    FlutterError(code: "INVALID_PLACEMENT_ID", message: "Placement ID is required", details: nil))
                return
            }
            guard let ch = channel else {
                result(FlutterError(code: "NO_CHANNEL", message: "Method channel unavailable", details: nil))
                return
            }
            guard let registrar = self.registrar else {
                result(FlutterError(code: "NO_REGISTRAR", message: "Plugin registrar unavailable", details: nil))
                return
            }

            print("📱 [NATIVE] Creating Native Ad View using bidscubeSdk for placement: \(placementId)")

            let adDelegate = FlutterAdDelegate(channel: ch)
            adDelegates["native_\(placementId)"] = adDelegate

            let nativeAdView = BidscubeSDK.getNativeAdView(placementId, adDelegate)

            let viewId = "native_native_ad_view_\(placementId)"
            registrar.register(NativeAdViewFactory(adView: nativeAdView), withId: viewId)

            result(["viewId": viewId])
        } catch {
            print("📱 [NATIVE] Error creating native ad view: \(error)")
            result(
                FlutterError(
                    code: "NATIVE_AD_ERROR",
                    message: "Failed to create native ad view: \(error.localizedDescription)",
                    details: nil
                ))
        }
    }

    private func getBannerAdView(placementId: String?, result: @escaping FlutterResult) {
        do {
            // TODO: Create and return actual banner ad view
            // For now, return a placeholder
            result("BannerAdView created for placement: \(placementId ?? "unknown")")
        } catch {
            result(
                FlutterError(
                    code: "BANNER_AD_ERROR",
                    message: "Failed to create banner ad view: \(error.localizedDescription)",
                    details: nil
                ))
        }
    }

    private func requestAd(placementId: String?, adType: String?, position: String?, result: @escaping FlutterResult) {
        do {
            // TODO: Request actual ad
            // For now, just return success
            result(
                "Ad requested for placement: \(placementId ?? "unknown"), type: \(adType ?? "unknown"), position: \(position ?? "unknown")")
        } catch {
            result(
                FlutterError(
                    code: "REQUEST_AD_ERROR",
                    message: "Failed to request ad: \(error.localizedDescription)",
                    details: nil
                ))
        }
    }

    private func removeAdCallback(placementId: String?, result: @escaping FlutterResult) {
        do {
            if let placementId = placementId {
                adDelegates.removeValue(forKey: "image_\(placementId)")
                adDelegates.removeValue(forKey: "video_\(placementId)")
                adDelegates.removeValue(forKey: "rewarded_\(placementId)")
                adDelegates.removeValue(forKey: "native_\(placementId)")
            }
            result("Ad callback removed for placement: \(placementId ?? "unknown")")
        } catch {
            result(
                FlutterError(
                    code: "REMOVE_CALLBACK_ERROR",
                    message: "Failed to remove ad callback: \(error.localizedDescription)",
                    details: nil
                ))
        }
    }

    private func requestConsentInfoUpdate(result: @escaping FlutterResult) {
        do {
            // TODO: Request actual consent info update
            // For now, just return success
            result("Consent info update requested")
        } catch {
            result(
                FlutterError(
                    code: "CONSENT_INFO_ERROR",
                    message: "Failed to request consent info update: \(error.localizedDescription)",
                    details: nil
                ))
        }
    }

    private func showConsentForm(result: @escaping FlutterResult) {
        do {
            // TODO: Show actual consent form
            // For now, just return success
            result("Consent form shown")
        } catch {
            result(
                FlutterError(
                    code: "CONSENT_FORM_ERROR",
                    message: "Failed to show consent form: \(error.localizedDescription)",
                    details: nil
                ))
        }
    }

    private func getSKAdNetworkIds(result: @escaping FlutterResult) {
        do {
            let skAdNetworkIds = BidscubeSDK.getSKAdNetworkIDs()
            result(skAdNetworkIds)
        } catch {
            result(
                FlutterError(
                    code: "SKADNETWORK_ERROR",
                    message: "Failed to get SKAdNetwork IDs: \(error.localizedDescription)",
                    details: nil
                ))
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
    private let channel: FlutterMethodChannel

    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    private func invoke(_ method: String, placementId: String, extras: [String: Any] = [:]) {
        var args: [String: Any] = ["placementId": placementId]
        for (k, v) in extras {
            args[k] = v
        }
        channel.invokeMethod(method, arguments: args)
    }

    func onAdLoading(_ placementId: String) {
        print("📱 [NATIVE→Dart] onAdLoading: \(placementId)")
        invoke("onAdLoading", placementId: placementId)
    }

    func onAdLoaded(_ placementId: String) {
        print("📱 [NATIVE→Dart] onAdLoaded: \(placementId)")
        invoke("onAdLoaded", placementId: placementId)
    }

    func onAdDisplayed(_ placementId: String) {
        print("📱 [NATIVE→Dart] onAdDisplayed: \(placementId)")
        invoke("onAdDisplayed", placementId: placementId)
    }

    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        print("📱 [NATIVE→Dart] onAdFailed: \(placementId) code=\(errorCode) \(errorMessage)")
        invoke(
            "onAdFailed",
            placementId: placementId,
            extras: [
                "errorCode": String(errorCode),
                "errorMessage": errorMessage,
            ])
    }

    func onAdClicked(_ placementId: String) {
        print("📱 [NATIVE→Dart] onAdClicked: \(placementId)")
        invoke("onAdClicked", placementId: placementId)
    }

    func onAdClosed(_ placementId: String) {
        print("📱 [NATIVE→Dart] onAdClosed: \(placementId)")
        invoke("onAdClosed", placementId: placementId)
    }

    func onVideoAdStarted(_ placementId: String) {
        print("📱 [NATIVE→Dart] onVideoAdStarted: \(placementId)")
        invoke("onVideoAdStarted", placementId: placementId)
    }

    func onVideoAdCompleted(_ placementId: String) {
        print("📱 [NATIVE→Dart] onVideoAdCompleted: \(placementId)")
        invoke("onVideoAdCompleted", placementId: placementId)
    }

    func onVideoAdSkipped(_ placementId: String) {
        print("📱 [NATIVE→Dart] onVideoAdSkipped: \(placementId)")
        invoke("onVideoAdSkipped", placementId: placementId)
    }

    func onUserRewarded(_ placementId: String) {
        print("📱 [NATIVE→Dart] onUserRewarded: \(placementId)")
        invoke("onUserRewarded", placementId: placementId)
    }
}
