//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

struct PopoverProfilesView: View {
    @ObservedObject var model: TelemetryModel = TelemetryModel.shared
    private var theme: AppTheme { AppTheme.current }
    
    // activeEPP slider values: 0=Ahorro, 1=Eq. Ahorro, 2=Eq. Rendimiento, 3=Rendimiento
    private var sliderValue: Binding<Double> {
        Binding<Double>(
            get: {
                switch model.cppcEPPValue {
                case 0x00...0x1F: return 3.0 // Rendimiento
                case 0x20...0x5F: return 2.0 // Equilibrado Rend.
                case 0x60...0x9F: return 1.0 // Equilibrado Ahorro
                case 0xA0...0xFF: return 0.0 // Power Saving
                default: return 2.0
                }
            },
            set: { val in
                let intVal = Int(round(val))
                var newEPP: UInt8 = 0x3F
                if intVal == 3 { newEPP = 0x00 }
                else if intVal == 2 { newEPP = 0x3F }
                else if intVal == 1 { newEPP = 0x80 }
                else if intVal == 0 { newEPP = 0xC0 }
                
                // Disable Auto EPP when user overrides manually
                if model.autoEPPEnabled { model.autoEPPEnabled = false }
                model.setCPPCEPPValue(epp: newEPP)
            }
        )
    }
    
    private var currentProfileName: String {
        switch model.cppcEPPValue {
         case 0x00...0x1F: return "Performance"
         case 0x20...0x5F: return "Balanced Perf."
         case 0x60...0x9F: return "Balanced Power"
         case 0xA0...0xFF: return "Power Saving"
         default: return "Unknown"
        }
    }
    
    private var currentProfileIcon: String {
        switch model.cppcEPPValue {
        case 0x00...0x1F: return "bolt.fill"
        case 0x20...0x5F: return "scale.3d"
        case 0x60...0x9F: return "leaf"
        case 0xA0...0xFF: return "leaf.fill"
        default: return "cpu"
        }
    }
    
    private var currentProfileColor: Color {
        switch model.cppcEPPValue {
        case 0x00...0x1F: return theme.accentRed
        case 0x20...0x5F: return theme.accentOrange
        case 0x60...0x9F: return theme.accentCyan
        case 0xA0...0xFF: return theme.accentGreen
        default: return theme.subtext
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // KDE Style Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(currentProfileColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: currentProfileIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(currentProfileColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.autoEPPEnabled ? LocalizedStringKey("Energy Profile (Auto-EPP Active)") : LocalizedStringKey("Energy Profile"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(model.autoEPPEnabled ? theme.accentCyan : theme.subtext)
                    Text(currentProfileName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.text)
                }
                Spacer()
            }
            .padding(.top, 4)
            
            // KDE Style Slider
            VStack(spacing: 8) {
                Slider(value: sliderValue, in: 0...3, step: 1)
                    .accentColor(currentProfileColor)
                    .disabled(model.autoEPPEnabled)
                
                HStack {
                    Text(LocalizedStringKey("Power Save"))
                        .font(.system(size: 9))
                        .foregroundColor(sliderValue.wrappedValue == 0 ? theme.text : theme.subtext)
                    Spacer()
                    Text(LocalizedStringKey("Balanced Power"))
                        .font(.system(size: 9))
                        .foregroundColor(sliderValue.wrappedValue == 1 ? theme.text : theme.subtext)
                    Spacer()
                    Text(LocalizedStringKey("Balanced Perf"))
                        .font(.system(size: 9))
                        .foregroundColor(sliderValue.wrappedValue == 2 ? theme.text : theme.subtext)
                    Spacer()
                    Text(LocalizedStringKey("Performance"))
                        .font(.system(size: 9))
                        .foregroundColor(sliderValue.wrappedValue == 3 ? theme.text : theme.subtext)
                }
                .opacity(model.autoEPPEnabled ? 0.5 : 1.0)
            }
            
            Divider().background(theme.cardBorder)
            
            // Advanced Toggles
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey("Advanced Controls"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(theme.subtext)
                
                Toggle(isOn: $model.autoEPPEnabled) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(theme.accentCyan)
                            .frame(width: 16)
                        Text("Auto EPP (Zen 3)")
                            .font(.system(size: 11))
                            .foregroundColor(theme.text)
                        
                        if model.autoEPPEnabled, let err = model.privilegeErrorMessage {
                            Image(systemName: "exclamationmark.shield.fill")
                                .font(.system(size: 10))
                                .foregroundColor(theme.accentRed)
                                .help(err)
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: theme.accentCyan))
                
                Toggle(isOn: $model.cpbEnabled) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(theme.accentOrange)
                            .frame(width: 16)
                        Text("Core Performance Boost")
                            .font(.system(size: 11))
                            .foregroundColor(theme.text)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: theme.accentOrange))
                .onChange(of: model.cpbEnabled) { newValue in
                    model.setCPB(enabled: newValue)
                }
            }
        }
        .padding(16)
    }
}

