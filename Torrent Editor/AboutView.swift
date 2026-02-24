import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {


            Image("avatar")                   // add Me.png or Me.jpg to Assets.xcassets
                .resizable()
                .scaledToFit()
                .frame(width: 150)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)

            // App name + version
            Text("MyMacApp")
                .font(.largeTitle)
                .bold()

            Text("Version \(appVersion)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider().padding(.vertical)

            Text("This is my custom About window made using SwiftUI.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button("OK") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .frame(width: 350, height: 420)
        .padding()
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}


#Preview {
    AboutView()
}
