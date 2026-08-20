// swift-tools-version: 5.9
import PackageDescription

// 只用于在没有 Xcode 的环境下对回收站纯逻辑跑单元测试。
// App target 直接编译 SPhoto/Core 下的源文件，不通过这个包引入。
let package = Package(
    name: "SPhotoCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    targets: [
        .target(name: "SPhotoCore", path: "SPhoto/Core"),
        .testTarget(
            name: "SPhotoCoreTests",
            dependencies: ["SPhotoCore"],
            path: "Tests/SPhotoCoreTests"
        ),
    ]
)
