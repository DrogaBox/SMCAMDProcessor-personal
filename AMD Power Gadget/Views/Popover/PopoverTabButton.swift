//
//  PopoverTabButton.swift
//  AMD Power Gadget
//
//  Moved from PopoverViews.swift during post-refactor cleanup
//

import SwiftUI

struct PopoverTabButton: View {
    let title: String
    let icon: String
    let tab: PopoverTab
    @Binding var currentTab: PopoverTab
    let theme: AppTheme
    
    var body: some View {
        Button(action: {
            currentTab = tab
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundColor(currentTab == tab ? theme.text : theme.subtext)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(currentTab == tab ? theme.cardBorder.opacity(0.8) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: currentTab)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
