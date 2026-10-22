import SwiftUI

@main
struct DucDuyExternalMenuApp: App {
    var body: some Scene {
        WindowGroup {
            MenuView()
                .preferredColorScheme(.dark)
        }
    }
}
