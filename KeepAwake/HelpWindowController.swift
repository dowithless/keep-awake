import AppKit

@MainActor
final class HelpWindowController: NSWindowController {
    private let textView = NSTextView()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        window.title = L10n.text("About & Help")
        window.minSize = NSSize(width: 420, height: 360)
        window.isReleasedWhenClosed = false
        super.init(window: window)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.textColor = .labelColor
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 14, height: 14)
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        scrollView.documentView = textView

        let links = NSStackView()
        links.orientation = .vertical
        links.alignment = .leading
        links.spacing = 8
        if Self.configuredURL("KeepAwakePrivacyPolicyURL") != nil {
            links.addArrangedSubview(NSButton(title: L10n.text("Privacy Policy"), target: self, action: #selector(openPrivacy)))
        }
        if Self.configuredURL("KeepAwakeSupportURL") != nil {
            links.addArrangedSubview(NSButton(title: L10n.text("Contact Support"), target: self, action: #selector(openSupport)))
        }
        if links.arrangedSubviews.isEmpty {
            links.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }

        let content = NSView()
        window.contentView = content
        for view in [scrollView, links] {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(view)
        }
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: links.topAnchor, constant: -16),
            links.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            links.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -20),
            links.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20)
        ])
        updateText()
        window.center()
    }

    required init?(coder: NSCoder) { fatalError("Use init()") }

    func present() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    private static func configuredURL(_ key: String) -> URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              let url = URL(string: value), url.scheme == "https", url.host != nil else { return nil }
        return url
    }

    @objc private func openPrivacy() {
        if let url = Self.configuredURL("KeepAwakePrivacyPolicyURL") { NSWorkspace.shared.open(url) }
    }
    @objc private func openSupport() {
        if let url = Self.configuredURL("KeepAwakeSupportURL") { NSWorkspace.shared.open(url) }
    }

    private func updateText() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let paragraphs = [
            "Keep Awake",
            L10n.format("Version %@ (%@)", version, build),
            Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? "",
            L10n.text("Left-click the menu bar cup to toggle Keep Awake. Right-click or Control-click to open the menu."),
            L10n.text("Keep Display Awake also prevents idle display sleep. Turn it off to let the display sleep while the Mac stays awake."),
            L10n.text("System sleep ends the current session. After waking, turn Keep Awake on again when needed. Launch at login never starts a session automatically."),
            L10n.text("Keep Awake does not prevent manual sleep or manual locking, unlock your Mac, or guarantee operation with the lid closed. System and organization security policies still apply."),
            L10n.text("Keep Awake works locally without an account. The app does not send personal data, usage analytics, or advertising identifiers to the developer."),
            L10n.text("Your display preference is stored on this Mac. Login items are managed by macOS. Operation errors may appear in local system logs; the app does not upload them."),
            L10n.text("Opening a support or privacy website uses your browser. Information you choose to send to support is handled separately from the app.")
        ].filter { !$0.isEmpty }
        textView.string = paragraphs.joined(separator: "\n\n")
        textView.setAccessibilityLabel(L10n.text("About & Help"))
        textView.scrollToBeginningOfDocument(nil)
    }
}
