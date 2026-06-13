//
//  SummaryTabView.swift
//  devpro3_G4
//
//  Created by 齊藤 洸希 on 2026/06/12.
//

import SwiftUI

struct SummaryTabView: View {
    @ObservedObject var viewModel: SensorDataViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // 最新のデータカード
                    if let latest = viewModel.statsDay.last {
                        Text("最新の状況").font(.title2).bold().padding(.horizontal)
                        
                        HStack(spacing: 15) {
                            SummaryCard(title: "気温", value: String(format: "%.1f", latest.avgTemp), unit: "℃", color: .red, icon: "thermometer.medium")
                            SummaryCard(title: "湿度", value: String(format: "%.0f", latest.avgHum), unit: "%", color: .blue, icon: "drop.fill")
                        }
                        .padding(.horizontal)
                    }
                    
                    // 各期間のサマリーセクション
                    Text("期間別サマリー").font(.title2).bold().padding(.horizontal).padding(.top, 10)
                    
                    VStack(spacing: 12) {
                        ForEach(GraphRange.allCases.filter { $0 != .day }, id: \.self) { range in
                            NavigationLink(destination: HistoryDetailView(viewModel: viewModel, range: range)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(range.rawValue).font(.headline).foregroundColor(.primary)
                                        let stats = viewModel.getStats(for: range)
                                        if let last = stats.last {
                                            Text("最終更新: \(last.date.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption).foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("概要")
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

// 概要用カード部品
struct SummaryCard: View {
    let title: String; let value: String; let unit: String; let color: Color; let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.subheadline).bold().foregroundColor(color)
            }
            HStack(alignment: .bottom, spacing: 2) {
                Text(value).font(.system(.title, design: .rounded)).bold()
                Text(unit).font(.caption).bold().foregroundColor(.secondary).padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
