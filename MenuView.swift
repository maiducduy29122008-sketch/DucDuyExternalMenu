import SwiftUI
import UniformTypeIdentifiers

struct AppConfig: Codable {
    var sensitivity: Double = 50
    var showFPSPreference: Bool = true
    var crosshairColor: String = "Cyan"
    var notes: String = "Standalone settings only; not connected to Free Fire."
}

struct MenuView: View {
    @AppStorage("sensitivity") private var sensitivity = 50.0
    @AppStorage("showFPSPreference") private var showFPSPreference = true
    @AppStorage("crosshairColor") private var crosshairColor = "Cyan"

    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportDocument = ConfigDocument()
    @State private var statusMessage: String?
    @State private var showStatus = false

    private let colors = ["Cyan", "Green", "White", "Magenta"]

    private var currentConfig: AppConfig {
        AppConfig(
            sensitivity: sensitivity,
            showFPSPreference: showFPSPreference,
            crosshairColor: crosshairColor
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color(red: 0.08, green: 0.10, blue: 0.16)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        header

                        VStack(alignment: .leading, spacing: 16) {
                            sectionTitle("LOCAL SETTINGS", icon: "slider.horizontal.3")

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Sensitivity preference")
                                    Spacer()
                                    Text("\(Int(sensitivity))")
                                        .monospacedDigit()
                                        .foregroundStyle(.cyan)
                                }
                                Slider(value: $sensitivity, in: 0...100, step: 1)
                                    .tint(.cyan)
                                Text("Saved locally on this iPhone. This value does not change game settings automatically.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Divider().overlay(Color.white.opacity(0.12))

                            Toggle("FPS display preference", isOn: $showFPSPreference)
                                .tint(.cyan)

                            Divider().overlay(Color.white.opacity(0.12))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Accent color")
                                Picker("Accent color", selection: $crosshairColor) {
                                    ForEach(colors, id: \.self) { color in
                                        Text(color).tag(color)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .panelStyle()

                        VStack(alignment: .leading, spacing: 14) {
                            sectionTitle("CONFIG FILE", icon: "doc.badge.gearshape")

                            Button {
                                exportDocument = ConfigDocument(config: currentConfig)
                                showExporter = true
                            } label: {
                                Label("Export configuration (.plist)", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())

                            Button {
                                showImporter = true
                            } label: {
                                Label("Import configuration (.plist)", systemImage: "square.and.arrow.down")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            Button(role: .destructive) {
                                sensitivity = 50
                                showFPSPreference = true
                                crosshairColor = "Cyan"
                                notify("Settings reset.")
                            } label: {
                                Label("Reset settings", systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        .panelStyle()

                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle("COMPATIBILITY", icon: "info.circle")
                            Text("This is a standalone iOS utility. On a non-jailbroken iPhone, iOS does not allow an ordinary app to draw over another app or directly modify Free Fire's process memory. Settings here are local preferences only.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .panelStyle()

                        Text("DUCDUY • EXTERNAL MENU CONCEPT")
                            .font(.caption2.weight(.semibold))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.top, 4)
                    }
                    .padding(16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.propertyList],
                allowsMultipleSelection: false,
                onCompletion: importConfig
            )
            .fileExporter(
                isPresented: $showExporter,
                document: exportDocument,
                contentType: .propertyList,
                defaultFilename: "DucDuyConfig",
                onCompletion: { result in
                    switch result {
                    case .success:
                        notify("Configuration exported.")
                    case .failure(let error):
                        notify("Export failed: \(error.localizedDescription)")
                    }
                }
            )
            .alert("DucDuy Menu", isPresented: $showStatus) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(statusMessage ?? "")
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cyan.opacity(0.14))
                    .frame(width: 58, height: 58)
                Image(systemName: "scope")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(.cyan)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("DUCDUY MENU")
                    .font(.title2.weight(.black))
                    .tracking(0.7)
                Text("Standalone iOS control panel")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
                .accessibilityLabel("App ready")
        }
        .padding(.vertical, 8)
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(.cyan)
    }

    private func importConfig(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let access = url.startAccessingSecurityScopedResource()
            defer {
                if access { url.stopAccessingSecurityScopedResource() }
            }
            let data = try Data(contentsOf: url)
            let config = try PropertyListDecoder().decode(AppConfig.self, from: data)
            sensitivity = min(100, max(0, config.sensitivity))
            showFPSPreference = config.showFPSPreference
            crosshairColor = colors.contains(config.crosshairColor) ? config.crosshairColor : "Cyan"
            notify("Configuration imported.")
        } catch {
            notify("Import failed: \(error.localizedDescription)")
        }
    }

    private func notify(_ message: String) {
        statusMessage = message
        showStatus = true
    }
}

private extension View {
    func panelStyle() -> some View {
        self
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.055))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.black)
            .padding(.vertical, 13)
            .background(Color.cyan.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 13)
            .background(Color.white.opacity(configuration.isPressed ? 0.12 : 0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ConfigDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.propertyList] }
    var config: AppConfig

    init(config: AppConfig = AppConfig()) {
        self.config = config
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        config = try PropertyListDecoder().decode(AppConfig.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(config)
        return FileWrapper(regularFileWithContents: data)
    }
}
