//
//  GraphTabView.swift
//  devpro3_G4
//
//  Created by 齊藤 洸希 on 2026/06/05.
//

import SwiftUI
import Charts

struct GraphTabView: View {
    @ObservedObject var viewModel: SensorDataViewModel
    @State private var selectedRange: GraphRange = .day
    
    // ▼ 修正：ここで宣言していた `@State private var scrollPosition` を削除しました
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("範囲", selection: $selectedRange) {
                        ForEach(GraphRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if viewModel.isCalculatingStats {
                        ProgressView("集計中...")
                            .frame(minHeight: 300)
                    } else {
                        let chartData = viewModel.getStats(for: selectedRange)
                        
                        HealthStyleChart(
                            title: "気温", unit: "℃", color: .red,
                            data: chartData, range: selectedRange, isTemperature: true
                            // ▼ 修正：引数としての scrollPosition を削除しました
                        )
                        
                        HealthStyleChart(
                            title: "湿度", unit: "%", color: .blue,
                            data: chartData, range: selectedRange, isTemperature: false
                            // ▼ 修正：引数としての scrollPosition を削除しました
                        )
                    }
                }
            }
            .navigationTitle("グラフ")
            .background(Color(UIColor.systemGroupedBackground))
            // ▼ 修正：.onChange と .onAppear も不要になったので削除しました（超軽量化！）
        }
    }
}

struct HealthStyleChart: View {
    let title: String; let unit: String; let color: Color; let data: [StatData]; let range: GraphRange; let isTemperature: Bool
    
    // ▼ 修正：ここで宣言していた `@Binding var scrollPosition` を削除しました
    @State private var selectedDate: Date?
    
    var currentStat: StatData? {
        if let selectedDate {
            return data.min(by: { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) })
        }
        return data.last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let stat = currentStat {
                VStack(alignment: .leading, spacing: 2) {
                    Text(range == .day ? title : "範囲").font(.caption).foregroundColor(.secondary).bold()
                    HStack(alignment: .bottom, spacing: 4) {
                        if range == .day {
                            Text(String(format: "%.1f", isTemperature ? stat.avgTemp : stat.avgHum)).font(.system(.title, design: .rounded)).bold()
                        } else {
                            let minV = isTemperature ? stat.minTemp : stat.minHum
                            let maxV = isTemperature ? stat.maxTemp : stat.maxHum
                            Text("\(Int(minV))–\(Int(maxV))").font(.system(.title, design: .rounded)).bold()
                        }
                        Text(unit).font(.headline).foregroundColor(.secondary).padding(.bottom, 4)
                    }
                    if range != .day {
                        Text("平均: \(String(format: "%.1f", isTemperature ? stat.avgTemp : stat.avgHum))\(unit)").font(.subheadline).foregroundColor(.secondary)
                    }
                    Text(formatHeaderDate(stat.date, for: range)).font(.caption).foregroundColor(.secondary)
                }
                .padding([.horizontal, .top])
            }
            
            Chart {
                ForEach(data) { item in
                    let minV = isTemperature ? item.minTemp : item.minHum
                    let maxV = isTemperature ? item.maxTemp : item.maxHum
                    let avgV = isTemperature ? item.avgTemp : item.avgHum
                    
                    if range == .day {
                        PointMark(x: .value("時", item.date), y: .value(title, avgV)).symbolSize(30).foregroundStyle(color)
                    } else {
                        BarMark(x: .value("日", item.date), yStart: .value("低", minV), yEnd: .value("高", maxV), width: range == .year ? .fixed(15) : .fixed(8))
                            .foregroundStyle(color.gradient).clipShape(Capsule())
                    }
                }
                if let selectedDate {
                    RuleMark(x: .value("選択", selectedDate)).foregroundStyle(.secondary.opacity(0.3))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatAxisDate(date, for: range))
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedDate)
            .chartScrollableAxes(.horizontal)
            // 🌟 超重要修正ポイント 🌟
            // 変数で監視するのをやめ、シンプルに「最新のデータ（一番右）」を初期位置に設定！
            .chartScrollPosition(initialX: data.last?.date ?? Date())
            .chartXVisibleDomain(length: range.seconds * (range == .day ? 24 : range == .week ? 7 : range == .month ? 30 : range == .sixMonths ? 26 : 12))
            // 🌟 魔法のコード 🌟
            // ピッカー（時・週・月）を切り替えた瞬間に、グラフをリセットして再び最新位置へ移動させる
            .id(range)
            .frame(height: 220)
            .padding()
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func formatAxisDate(_ date: Date, for range: GraphRange) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP")
        let comp = Calendar.current.dateComponents([.month, .day, .hour], from: date)
        
        // 1月1日（年の境界）なら、必ず西暦を表示する
        if comp.month == 1 && comp.day == 1 && (comp.hour ?? 0) < 12 {
            return date.formatted(.dateTime.year())
        }
        
        switch range {
        case .day: f.dateFormat = "HH:mm"
        case .week, .month: f.dateFormat = "M/d"
        case .sixMonths: f.dateFormat = "M月"
        case .year: f.dateFormat = "yyyy年"
        }
        return f.string(from: date)
    }
    
    private func formatHeaderDate(_ date: Date, for range: GraphRange) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP")
        switch range {
        case .day: f.dateFormat = "yyyy年M月d日 HH:mm"
        case .week, .month: f.dateFormat = "yyyy年M月d日"
        case .sixMonths: f.dateFormat = "yyyy年M月d日の週"
        case .year: f.dateFormat = "yyyy年M月"
        }
        return f.string(from: date)
    }
}
