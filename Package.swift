// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "SalaryTicker",
  platforms: [.macOS(.v14)],
  targets: [
    .executableTarget(name: "SalaryTicker"),
    .testTarget(name: "SalaryTickerTests", dependencies: ["SalaryTicker"]),
  ]
)
