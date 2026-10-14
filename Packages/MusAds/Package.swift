// swift-tools-version: 5.9
import PackageDescription

// Módulo aislado de anuncios: es el único sitio que conoce el SDK de Google.
// MusCore y las pantallas del marcador no dependen de él.
let package = Package(
    name: "MusAds",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "MusAds", targets: ["MusAds"]),
    ],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", exact: "13.11.0"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git", exact: "3.1.0"),
    ],
    targets: [
        .target(
            name: "MusAds",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                .product(name: "GoogleUserMessagingPlatform", package: "swift-package-manager-google-user-messaging-platform"),
            ]
        ),
    ]
)
