//
//  ContentView.swift
//  devpro3_G4
//
//  Created by 齊藤 洸希 on 2026/06/05.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SensorDataViewModel()
    
    var body: some View {
        TabView {
            // 1. 概要（起動時に最初に表示される）
            SummaryTabView(viewModel: viewModel)
                .tabItem {
                    Label("概要", systemImage: "doc.text.magnifyingglass")
                }
            
            // 2. グラフ
            GraphTabView(viewModel: viewModel)
                .tabItem {
                    Label("グラフ", systemImage: "chart.xyaxis.line")
                }
            
            // 3. 履歴
            HistoryTabView(viewModel: viewModel)
                .tabItem {
                    Label("履歴", systemImage: "list.dash")
                }
        }
        .task {
            await viewModel.startFetching()
        }
    }
}
