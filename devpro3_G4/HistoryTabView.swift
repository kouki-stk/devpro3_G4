//
//  HistoryTabView.swift
//  devpro3_G4
//
//  Created by 齊藤 洸希 on 2026/06/05.
//

import SwiftUI

struct HistoryTabView: View {
    @ObservedObject var viewModel: SensorDataViewModel
    
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    
    private var filteredRows: [SensorData] {
        let cal = Calendar.current
        return viewModel.allRawData.filter { item in
            cal.isDate(item.timestamp, inSameDayAs: selectedDate)
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationStack {
            // ▼ 修正：VStackを廃止し、全体をListで包むことでタイトルの重なりを防止！
            List {
                // --- 1行目：カレンダー選択（背景を透明にして浮かせる） ---
                Section {
                    HStack {
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
                            .frame(width: 320)
                            .presentationCompactAdaptation(.popover)
                            .padding()
                        }
                        
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear) // セル特有の背景を消して自然に配置
                .listRowInsets(EdgeInsets(top: 10, leading: 4, bottom: 10, trailing: 0))
                .listRowSeparator(.hidden)
                
                // --- 2行目以降：履歴リスト ---
                if filteredRows.isEmpty {
                    VStack {
                        Spacer()
                        Text("この日のデータはありません")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    Section(header: Text("\(filteredRows.count) 件のデータ (新しい順)")) {
                        ForEach(filteredRows) { row in
                            HStack {
                                Text(row.timestamp.formatted(.dateTime.hour().minute().second()))
                                    .font(.body.monospacedDigit())
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "thermometer.medium").foregroundColor(.red)
                                    Text(String(format: "%.1f℃", row.temperature))
                                        .font(.body.monospacedDigit())
                                }
                                
                                Spacer()
                                
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
            }
            .listStyle(.insetGrouped) // 純正アプリライクな美しいリスト構造
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
