//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

struct InfoRow: View {
    let label: LocalizedStringKey; let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(.tahoeSubtext)
            Spacer()
            Text(value).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(.tahoeText).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

