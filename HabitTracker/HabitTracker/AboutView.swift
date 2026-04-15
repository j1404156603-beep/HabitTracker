import SwiftUI

struct AboutView: View {
    private var versionString: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        let shortPart = short ?? "-"
        let buildPart = build ?? "-"
        return "\(shortPart) (\(buildPart))"
    }

    var body: some View {
        List {
            Section("about_section_version") {
                LabeledContent("about_version_number", value: versionString)
            }
        }
        .navigationTitle("about_title")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.theme.background)
        .toolbarBackground(Color.theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

