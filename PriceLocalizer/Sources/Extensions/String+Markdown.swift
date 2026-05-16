import SwiftUI

extension String {
    func markdownWithUnderlinedLinks() -> AttributedString {
        guard var attr = try? AttributedString(markdown: self) else {
            return AttributedString(self)
        }
        for run in attr.runs where run.link != nil {
            attr[run.range].underlineStyle = .single
        }
        return attr
    }
}
