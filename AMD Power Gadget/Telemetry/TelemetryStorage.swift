//
//  TelemetryStorage.swift
//  AMD Power Gadget
//

import Foundation

// MARK: - Chart Size Config

struct ChartSizeConfig {
    static let shared = ChartSizeConfig()
    private let ud = UserDefaults.standard

    var dashboardHeight: CGFloat {
        get { CGFloat(ud.double(forKey: "chart_dash_h")) }
        set { ud.set(Double(newValue), forKey: "chart_dash_h") }
    }
    var telemetryBarHeight: CGFloat {
        get { CGFloat(ud.double(forKey: "chart_tbar_h")) }
        set { ud.set(Double(newValue), forKey: "chart_tbar_h") }
    }
    var telemetryLineHeight: CGFloat {
        get { CGFloat(ud.double(forKey: "chart_tline_h")) }
        set { ud.set(Double(newValue), forKey: "chart_tline_h") }
    }

    init() {
        if ud.object(forKey: "chart_dash_h") == nil { ud.set(100.0, forKey: "chart_dash_h") }
        if ud.object(forKey: "chart_tbar_h") == nil { ud.set(140.0, forKey: "chart_tbar_h") }
        if ud.object(forKey: "chart_tline_h") == nil { ud.set(80.0, forKey: "chart_tline_h") }
    }
}


// MARK: - Simple Deque Ring Buffer
struct SimpleDeque<T> {
    private var array: [T?]
    private var head: Int = 0
    private var tail: Int = 0
    private(set) var count: Int = 0
    
    init(capacity: Int) {
        self.array = Array(repeating: nil, count: capacity)
    }
    
    mutating func append(_ element: T) {
        if count == array.count {
            array[tail] = element
            tail = (tail + 1) % array.count
            head = (head + 1) % array.count
        } else {
            array[tail] = element
            tail = (tail + 1) % array.count
            count += 1
        }
    }
    
    mutating func clear() {
        array = Array(repeating: nil, count: array.count)
        head = 0
        tail = 0
        count = 0
    }
    
    var elements: [T] {
        var result: [T] = []
        result.reserveCapacity(count)
        for i in 0..<count {
            if let el = array[(head + i) % array.count] {
                result.append(el)
            }
        }
        return result
    }
}

// MARK: - MetricHistory
struct MetricHistory {
    let capacity: Int
    private(set) var values: [Double] = []

    init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    mutating func push(_ value: Double) {
        values.append(value)
        if values.count > capacity {
            values.removeFirst(values.count - capacity)
        }
    }
}

