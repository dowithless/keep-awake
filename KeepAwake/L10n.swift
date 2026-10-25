import Foundation

/// English source strings are also the fallback for unrecognized languages.
/// Entries are maintained in Localizable.xcstrings, including AppKit strings.
enum L10n {
    static func text(_ source: String) -> String {
        Bundle.main.localizedString(forKey: source, value: source, table: "Localizable")
    }

    static func format(_ source: String, _ arguments: CVarArg...) -> String {
        String(format: text(source), locale: Locale.current, arguments: arguments)
    }
}
