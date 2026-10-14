import GoogleMobileAds
import SwiftUI
import UIKit

/// Banner adaptativo anclado. Ocupa **cero** altura hasta que llega un anuncio: sin red, sin consentimiento
/// o ante un fallo no se ve nada ni queda ningún hueco.
public struct AdBanner: View {
    let controller: AdsController
    @State private var height: CGFloat = 0

    public init(controller: AdsController) {
        self.controller = controller
    }

    public var body: some View {
        Group {
            if controller.canShowAds, let unitID = controller.configuration?.bannerUnitID {
                GeometryReader { proxy in
                    BannerRepresentable(unitID: unitID, width: proxy.size.width) { height = $0 }
                }
                .frame(height: height)
                .accessibilityLabel("Publicidad")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct BannerRepresentable: UIViewRepresentable {
    let unitID: String
    let width: CGFloat
    let onHeight: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onHeight: onHeight) }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        let banner = BannerView()
        banner.adUnitID = unitID
        banner.delegate = context.coordinator
        banner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            banner.topAnchor.constraint(equalTo: container.topAnchor),
        ])
        context.coordinator.banner = banner
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        context.coordinator.onHeight = onHeight
        guard let banner = context.coordinator.banner, width > 0 else { return }
        banner.rootViewController = container.window?.rootViewController
        // Solo se recarga si cambia el ancho (p. ej. al girar el iPhone).
        guard abs(context.coordinator.loadedWidth - width) > 1 else { return }
        context.coordinator.loadedWidth = width
        banner.adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
        banner.load(Request())
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        var onHeight: (CGFloat) -> Void
        var banner: BannerView?
        var loadedWidth: CGFloat = 0

        init(onHeight: @escaping (CGFloat) -> Void) { self.onHeight = onHeight }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            onHeight(bannerView.adSize.size.height)
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            onHeight(0)
        }
    }
}
