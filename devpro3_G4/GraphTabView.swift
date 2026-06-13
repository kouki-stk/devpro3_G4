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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 期間切り替えピッカー
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
                        // 気温グラフ
                        HealthStyleChart(
                            title: "気温",
                            unit: "℃",
                            color: .red,
                            data: viewModel.getStats(for: selectedRange),
                            range: selectedRange,
                            isTemperature: true
                        )
                        
                        // 湿度グラフ
                        HealthStyleChart(
                            title: "湿度",
                            unit: "%",
                            color: .blue,
                            data: viewModel.getStats(for: selectedRange),
                            range: selectedRange,
                            isTemperature: false
                        )
                    }
                }
            }
            .navigationTitle("グラフ")
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

struct HealthStyleChart: View {
    let title: String
    let unit: String
    let color: Color
    let data: [StatData]
    let range: GraphRange
    let isTemperature: Bool
    
    @State private var selectedDate: Date?
    
    // ▼ 爆速化の要：グラフに渡すデータを「直近300件」に制限する
    private var displayData: [StatData] {
        Array(data.suffix(300))
    }
    
    // ▼ 選択されたデータ、または最新データを displayData の中から探す
    var currentStat: StatData? {
        if let selectedDate {
            return displayData.min(by: { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) })
        }
        return displayData.last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // --- ヘッダー情報（タップ連動） ---
            if let stat = currentStat {
                VStack(alignment: .leading, spacing: 2) {
                    Text(range == .day ? title : "範囲")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .bold()
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        if range == .day {
                            Text(String(format: "%.1f", isTemperature ? stat.avgTemp : stat.avgHum))
                                .font(.system(.title, design: .rounded))
                                .bold()
                        } else {
                            let minV = isTemperature ? stat.minTemp : stat.minHum
                            let maxV = isTemperature ? stat.maxTemp : stat.maxHum
                            Text("\(Int(minV))–\(Int(maxV))")
                                .font(.system(.title, design: .rounded))
                                .bold()
                        }
                        Text(unit)
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                    
                    if range != .day {
                        Text("平均: \(String(format: "%.1f", isTemperature ? stat.avgTemp : stat.avgHum))\(unit)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(formatHeaderDate(stat.date, for: range))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding([.horizontal, .top])
            }
            
            // --- グラフ本体 ---
            Chart {
                // displayData を使って描画を軽量化
                ForEach(displayData) { item in
                    let minV = isTemperature ? item.minTemp : item.minHum
                    let maxV = isTemperature ? item.maxTemp : item.maxHum
                    let avgV = isTemperature ? item.avgTemp : item.avgHum
                    
                    if range == .day {
                        // 「時」は点グラフ（平均値）
                        PointMark(
                            x: .value("時", item.date),
                            y: .value(title, avgV)
                        )
                        .symbolSize(30)
                        .foregroundStyle(color)
                    } else {
                        // 「週・月・6ヶ月・年」は範囲を示すカプセル状の棒グラフ
                        BarMark(
                            x: .value("日", item.date),
                            yStart: .value("低", minV),
                            yEnd: .value("高", maxV),
                            width: range == .year ? .fixed(15) : .fixed(8)
                        )
                        .foregroundStyle(color.gradient)
                        .clipShape(Capsule())
                    }
                }
                
                // タップした時の縦線
                if let selectedDate {
                    RuleMark(x: .value("選択", selectedDate))
                        .foregroundStyle(.secondary.opacity(0.3))
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
            // データが密集しすぎないように、画面幅に表示する期間を固定
            .chartXVisibleDomain(length: range.seconds * (range == .day ? 24 : range == .week ? 7 : range == .month ? 30 : range == .sixMonths ? 26 : 12))
            .frame(height: 220)
            .padding()
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // X軸の下に表示する日付のフォーマット
    private func formatAxisDate(_ date: Date, for range: GraphRange) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        switch range {
        case .day: f.dateFormat = "HH:mm"
        case .week, .month: f.dateFormat = "M/d"
        case .sixMonths: f.dateFormat = "M月"
        case .year: f.dateFormat = "yyyy年"
        }
        return f.string(from: date)
    }
    
    // ヘッダーに表示する詳細な日付のフォーマット
    private func formatHeaderDate(_ date: Date, for range: GraphRange) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        switch range {
        case .day: f.dateFormat = "yyyy年M月d日 HH:mm"
        case .week, .month: f.dateFormat = "yyyy年M月d日"
        case .sixMonths: f.dateFormat = "yyyy年M月d日の週"
        case .year: f.dateFormat = "yyyy年M月"
        }
        return f.string(from: date)
    }
}
