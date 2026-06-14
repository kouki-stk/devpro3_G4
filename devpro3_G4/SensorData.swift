//
//  SensorData.swift
//  devpro3_G4
//
//  Created by 齊藤 洸希 on 2026/06/05.
//

import Foundation
import SwiftUI
import Combine
import ActivityKit // 💡 ライブアクティビティ制御のために追加

public enum GraphRange: String, CaseIterable, Sendable {
    case day = "時", week = "週", month = "月", sixMonths = "6か月", year = "年"
    public var seconds: Double {
        switch self {
        case .day: return 3600
        case .week: return 86400
        case .month: return 86400
        case .sixMonths: return 604800
        case .year: return 2592000
        }
    }
}

public struct SensorData: Codable, Identifiable, Equatable, @unchecked Sendable {
    public var id: Date { timestamp }
    public let timestamp: Date
    public let temperature: Double
    public let humidity: Double
}

public struct StatData: Identifiable, @unchecked Sendable {
    public let id = UUID()
    public let date: Date
    public let minTemp: Double, maxTemp: Double, avgTemp: Double
    public let minHum: Double, maxHum: Double, avgHum: Double
}

@MainActor
public class SensorDataViewModel: ObservableObject {
    @Published public var statsDay: [StatData] = []
    @Published public var statsWeek: [StatData] = []
    @Published public var statsMonth: [StatData] = []
    @Published public var statsSixMonths: [StatData] = []
    @Published public var statsYear: [StatData] = []
    @Published public var isCalculatingStats: Bool = false
    @Published public var isDataLoaded: Bool = false
    
    // 起動中のライブアクティビティを管理する変数
    private var currentActivity: Activity<SensorActivityAttributes>?
    
    public func startFetching() async {
        guard !isCalculatingStats && !isDataLoaded else { return }
        guard let url = URL(string: "http://192.168.1.40:5001/api/data") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                if let date = formatter.date(from: dateString) { return date }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date")
            }
            let fetched = try decoder.decode([SensorData].self, from: data).sorted { $0.timestamp < $1.timestamp }
            
            self.isCalculatingStats = true
            let cal = Calendar.current
            
            let results = await Task.detached(priority: .userInitiated) {
                return (
                    SensorDataViewModel.aggregate(.day, fetched, cal),
                    SensorDataViewModel.aggregate(.week, fetched, cal),
                    SensorDataViewModel.aggregate(.month, fetched, cal),
                    SensorDataViewModel.aggregate(.sixMonths, fetched, cal),
                    SensorDataViewModel.aggregate(.year, fetched, cal)
                )
            }.value
            
            self.statsDay = results.0
            self.statsWeek = results.1
            self.statsMonth = results.2
            self.statsSixMonths = results.3
            self.statsYear = results.4
            
            self.isCalculatingStats = false
            self.isDataLoaded = true
            
            // ▼ 追加：最新データが取れたらライブアクティビティを起動・更新する
            if let latestData = fetched.last {
                updateLiveActivity(latest: latestData)
            }
            
        } catch { print("Fetch error: \(error)") }
    }
    
    // ▼ 追加：ライブアクティビティの開始・更新ロジック
    private func updateLiveActivity(latest: SensorData) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let state = SensorActivityAttributes.ContentState(
            temperature: latest.temperature,
            humidity: latest.humidity,
            updateTime: latest.timestamp
        )
        let content = ActivityContent(state: state, staleDate: nil)
        
        if let activity = currentActivity {
            // すでに島やロック画面に出ていればデータを最新にする（パラパラ数字アニメーションが発動）
            Task { await activity.update(content) }
        } else {
            // アプリ起動時に新しくアクティビティをリクエストする
            do {
                let attributes = SensorActivityAttributes()
                currentActivity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } catch {
                print("Live Activity Error: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated static func aggregate(_ range: GraphRange, _ data: [SensorData], _ cal: Calendar) -> [StatData] {
        let grouped = Dictionary(grouping: data) { item -> Date in
            if range == .day { return cal.date(bySettingHour: cal.component(.hour, from: item.timestamp), minute: 0, second: 0, of: item.timestamp) ?? item.timestamp }
            else if range == .year { let comp = cal.dateComponents([.year, .month], from: item.timestamp); return cal.date(from: comp) ?? item.timestamp }
            else if range == .sixMonths { let comp = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: item.timestamp); return cal.date(from: comp) ?? item.timestamp }
            else { return cal.startOfDay(for: item.timestamp) }
        }
        return grouped.map { date, values in
            let temps = values.map { $0.temperature }; let hums = values.map { $0.humidity }
            return StatData(date: date, minTemp: temps.min() ?? 0, maxTemp: temps.max() ?? 0, avgTemp: temps.isEmpty ? 0 : temps.reduce(0, +) / Double(temps.count), minHum: hums.min() ?? 0, maxHum: hums.max() ?? 0, avgHum: hums.isEmpty ? 0 : hums.reduce(0, +) / Double(hums.count))
        }.sorted { $0.date < $1.date }
    }
    
    public func getStats(for range: GraphRange) -> [StatData] {
        switch range { case .day: return statsDay; case .week: return statsWeek; case .month: return statsMonth; case .sixMonths: return statsSixMonths; case .year: return statsYear }
    }
}
