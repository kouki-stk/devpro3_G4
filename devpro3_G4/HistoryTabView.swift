//
//  HistoryTabView.swift
//  devpro3_G4
//
//  Created by 齊藤 洸希 on 2026/06/05.
//

import SwiftUI

struct HistoryTabView: View {
    @ObservedObject var viewModel: SensorDataViewModel
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(GraphRange.allCases, id: \.self) { range in
                    NavigationLink(destination: HistoryDetailView(viewModel: viewModel, range: range)) {
                        HStack(spacing: 15) {
                            Image(systemName: "calendar")
                                .foregroundColor(.accentColor)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("\(range.rawValue)ごとの詳細")
                                    .font(.body).bold()
                                Text("\(viewModel.getStats(for: range).count) 件のデータ")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("履歴")
        }
    }
}

// 履歴詳細画面（リストデザイン）
struct HistoryDetailView: View {
    @ObservedObject var viewModel: SensorDataViewModel
    let range: GraphRange
    
    var body: some View {
        List(viewModel.getStats(for: range)) { stat in
            VStack(alignment: .leading, spacing: 8) {
                Text(formatDate(stat.date, for: range))
                    .font(.caption).bold().foregroundColor(.secondary)
                
                HStack {
                    HStack {
                        Image(systemName: "thermometer.medium").foregroundColor(.red)
                        Text(String(format: "%.1f℃", stat.avgTemp)).font(.body.monospacedDigit())
                    }
                    Spacer()
                    HStack {
                        Image(systemName: "drop.fill").foregroundColor(.blue)
                        Text(String(format: "%.0f%%", stat.avgHum)).font(.body.monospacedDigit())
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("\(range.rawValue)の履歴")
        .listStyle(.insetGrouped)
    }
    
    private func formatDate(_ date: Date, for range: GraphRange) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = (range == .day) ? "M/d HH:mm" : "yyyy/M/d"
        return f.string(from: date)
    }
}
