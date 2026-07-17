//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

struct RawField: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 8, weight: .semibold)).foregroundColor(.tahoeSubtext)
            TextField("", text: $value)
                .textFieldStyle(.plain)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.tahoeText)
                .padding(4)
                .background(Color.tahoeBackground.opacity(0.3))
                .cornerRadius(4)
        }
    }
}
struct TempThresholdField: View {
    @Binding var value: Int
    @State private var text = ""
    
    var body: some View {
        HStack(spacing: 4) {
            TextField("", text: $text, onEditingChanged: { editing in
                if !editing {
                    if let val = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        value = max(30, min(100, val))
                    }
                    text = "\(value)"
                }
            })
            .textFieldStyle(.plain)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.tahoeAccentOrange)
            .multilineTextAlignment(.trailing)
            .frame(width: 45)
            .onAppear {
                text = "\(value)"
            }
            .onChange(of: value) { newValue in
                text = "\(newValue)"
            }
            
            Text("°C")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.tahoeSubtext)
        }
        .padding(.vertical, 4).padding(.horizontal, 8)
        .background(Color.tahoeBackground.opacity(0.4))
        .cornerRadius(6)
    }
}

struct VerticalLabelView: View {
    let text: String
    var body: some View {
        let chars = Array(text.map { String($0) })
        VStack(spacing: -1.5) {
            ForEach(0..<chars.count, id: \.self) { idx in
                Text(chars[idx])
                    .font(.system(size: 7.2, weight: .regular, design: .monospaced))
            }
        }
        .frame(width: 7)
        .foregroundColor(.white.opacity(0.8))
    }
}

