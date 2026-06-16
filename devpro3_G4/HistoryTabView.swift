//
//  HistoryTabView.swift
//  devpro3_G4
//
//  Created by 齊藤 洸希 on 2026/06/05.
//

import SwiftUI

struct HistoryTabView: View {
    @ObservedObject var viewModel: SensorDataViewModel
    
    // カレンダーで選択された日付（デフォルトは今日）
    @State private var selectedDate = Date()
    // カレンダーのポップアップを表示するかどうかの管理フラグ
    @State private var showDatePicker = false
    
    // 選択された日付のデータを抽出し、新→古（降順）にソート
    private var filteredRows: [SensorData] {
        let cal = Calendar.current
        return viewModel.allRawData.filter { item in
            cal.isDate(item.timestamp, inSameDayAs: selectedDate)
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // --- カレンダー選択セクション ---
                HStack {
                    // タップするとカレンダーが展開する文字だけのボタン
                    Button(action: { showDatePicker.toggle() }) {
                        HStack(spacing: 6) {
                            Text(formatSelectedDate(selectedDate))
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.semibold)
                                .monospacedDigit()
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.down")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    // ∨を押したときに表示されるポップアップカレンダーの設定
                    .popover(isPresented: $showDatePicker) {
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                        .environment(\.calendar, Calendar(identifier: .gregorian))
                        // ▼ 修正の核心：カレンダーが細く潰れないように、明示的に横幅(320)を指定！
                        .frame(width: 320)
                        .presentationCompactAdaptation(.popover)
                        .padding()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(UIColor.systemGroupedBackground))
                
                // --- 履歴リストセクション ---
                if filteredRows.isEmpty {
                    VStack {
                        Spacer()
                        Text("この日のデータはありません")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGroupedBackground))
                } else {
                    List {
                        Section(header: Text("\(filteredRows.count) 件のデータ (新しい順)")) {
                            ForEach(filteredRows) { row in
                                HStack {
                                    // 時間
                                    Text(row.timestamp.formatted(.dateTime.hour().minute().second()))
                                        .font(.body.monospacedDigit())
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    // 気温
                                    HStack(spacing: 4) {
                                        Image(systemName: "thermometer.medium").foregroundColor(.red)
                                        Text(String(format: "%.1f℃", row.temperature))
                                            .font(.body.monospacedDigit())
                                    }
                                    
                                    Spacer()
                                    
                                    // 湿度
                                    HStack(spacing: 4) {
                                        Image(systemName: "drop.fill").foregroundColor(.blue)
                                        Text(String(format: "%.0f%%", row.humidity))
                                            .font(.body.monospacedDigit())
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("履歴")
        }
    }
    
    private func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
