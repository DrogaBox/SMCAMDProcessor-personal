//
//  TelemetryPerformance.swift
//  AMD Power Gadget
//

import Foundation
import SwiftUI
import Combine

struct ThresholdPublished<Value: SignedNumeric & Comparable> {
    private var value: Value
    private let threshold: Value
    private let subject = PassthroughSubject<Value, Never>()
    
    var wrappedValue: Value {
        get { value }
        set {
            if abs(newValue - value) >= threshold {
                value = newValue
                subject.send(newValue)
            }
        }
    }
    
    var projectedValue: AnyPublisher<Value, Never> {
        subject.eraseToAnyPublisher()
    }
    
    init(wrappedValue: Value, threshold: Value) {
        self.value = wrappedValue
        self.threshold = threshold
    }
}

// MARK: - Performance Optimization: View Visibility Tracking

/// Helper para rastrear si una vista está visible y solo renderizar gráficos cuando sea necesario
struct ViewVisibilityModifier: ViewModifier {
    @State private var isVisible = false
    var onVisibilityChange: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear { 
                isVisible = true
                onVisibilityChange(true)
            }
            .onDisappear { 
                isVisible = false
                onVisibilityChange(false)
            }
    }
}

extension View {
    func trackVisibility(onChange: @escaping (Bool) -> Void) -> some View {
        modifier(ViewVisibilityModifier(onVisibilityChange: onChange))
    }
}

// MARK: - Performance Optimization: Calculation Cache

/// Cache para cálculos costosos de gráficos
/// Evita recalcular valores cuando los inputs no cambian significativamente
struct CalculationCache<Value: Equatable> {
    private var cachedValue: Value?
    private var cacheKey: String = ""
    private let ttl: TimeInterval
    private var lastUpdate: Date = .distantPast
    
    mutating func getValue(key: String, calculate: @escaping () -> Value) -> Value {
        let now = Date()
        
        // Invalidar cache si expiró o la key cambió
        if cacheKey != key || now.timeIntervalSince(lastUpdate) > ttl {
            cacheKey = key
            cachedValue = calculate()
            lastUpdate = now
        }
        
        return cachedValue ?? calculate()
    }
    
    mutating func invalidate() {
        lastUpdate = .distantPast
        cachedValue = nil
    }
    
    init(ttl: TimeInterval = 1.0) {
        self.ttl = ttl
    }
}

// MARK: - Performance Optimization: Performance Monitor

/// Monitor interno para rastrear métricas de performance
struct PerformanceMonitor {
    private var sampleCount: Int = 0
    private var totalSampleTime: TimeInterval = 0
    private var lastSampleTime: Date = Date()
    private var peakMemory: UInt64 = 0
    
    mutating func recordSample(duration: TimeInterval) {
        sampleCount += 1
        totalSampleTime += duration
        
        // Rastrear pico de memoria cada 100 samples
        if sampleCount % 100 == 0 {
            let used = ProcessInfo.processInfo.physicalMemory / 1024 / 1024 // MB
            if used > peakMemory {
                peakMemory = UInt64(used)
            }
        }
    }
    
    var averageSampleTime: TimeInterval {
        sampleCount > 0 ? totalSampleTime / Double(sampleCount) : 0
    }
    
    var peakMemoryMB: UInt64 {
        peakMemory
    }
    
    mutating func reset() {
        sampleCount = 0
        totalSampleTime = 0
        peakMemory = 0
    }
}

// MARK: - Diagnostics Helper

/// Helper para diagnostics y debugging en producción
struct DiagnosticsHelper {
    static func logSystemInfo() {
        let device = NSScreen.main?.localizedName ?? "Unknown"
        let memory = ProcessInfo.processInfo.physicalMemory / 1024 / 1024 / 1024
        let processors = ProcessInfo.processInfo.processorCount
        NSLog("System Info: Device=%@, Memory=%lld GB, Processors=%d", device, memory, processors)
    }
    
    static func logPerformanceMetrics(avgSampleTime: TimeInterval, peakMemory: UInt64) {
        NSLog("Performance: Avg Sample=%.2fms, Peak Memory=%lld MB", avgSampleTime * 1000, peakMemory)
    }
    
    static func logConcurrencyStatus(dataRaceDetected: Bool, mainThreadBlocked: Bool) {
        let status = dataRaceDetected ? "UNSAFE" : "SAFE"
        let mainThread = mainThreadBlocked ? "BLOCKED" : "RESPONSIVE"
        NSLog("Concurrency Status: %@, MainThread: %@", status, mainThread)
    }
}

