//
//  CaffeinateManager.swift
//  AMD Power Gadget
//

import Foundation
import IOKit

// MARK: - CaffeinateManager
import IOKit.pwr_mgt

@MainActor
final class CaffeinateManager: ObservableObject {
    static let shared = CaffeinateManager()
    
    @Published var isAwake: Bool = false {
        didSet {
            if isAwake {
                startAssertion()
            } else {
                releaseAssertion()
            }
        }
    }
    
    private var assertionID: IOPMAssertionID = 0
    private var assertionCreated: Bool = false
    private var timer: Timer?

    func toggle() {
        isAwake.toggle()
    }
    
    func keepAwakeFor(hours: Double) {
        isAwake = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: hours * 3600, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isAwake = false
            }
        }
    }

    private func startAssertion() {
        guard !assertionCreated else { return }
        let reasonForActivity = "AMD Power Gadget User Requested Keep Awake" as CFString
        let success = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reasonForActivity,
            &assertionID
        )
        if success == kIOReturnSuccess {
            assertionCreated = true
        } else {
            isAwake = false
        }
    }
    
    private func releaseAssertion() {
        if assertionCreated {
            IOPMAssertionRelease(assertionID)
            assertionCreated = false
        }
        timer?.invalidate()
        timer = nil
    }
}
