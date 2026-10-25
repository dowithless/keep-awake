import Foundation
import Darwin

func fail(_ message: String) -> Never {
    fputs(message + "\n", stderr)
    exit(EXIT_FAILURE)
}

// Run against a built app: <probe> <app-path> <expected-menu-title>
// -AppleLanguages '(ru)' can be supplied to this process without changing macOS settings.
guard CommandLine.arguments.count >= 3,
      let bundle = Bundle(path: CommandLine.arguments[1]) else {
    fail("Usage: LocalizationRuntimeProbe <app-path> <expected-menu-title> [-AppleLanguages '(language)']")
}
let actual = bundle.localizedString(forKey: "Keep Awake", value: "Keep Awake", table: "Localizable")
guard actual == CommandLine.arguments[2] else { fail("Wrong runtime language: \(actual), main languages: \(Bundle.main.preferredLocalizations)") }
let version = bundle.localizedString(forKey: "Version %@ (%@)", value: "Version %@ (%@)", table: "Localizable")
let formatted = String(format: version, "1.0", "1")
guard formatted.contains("1.0") && !formatted.contains("%@") else { fail("Invalid localized format") }
print("PASS: \(bundle.preferredLocalizations.joined(separator: ",")) — \(actual) — \(formatted)")
