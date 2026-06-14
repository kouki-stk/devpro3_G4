//
//  ContentView.swift
//  devpro3_G4
//
//  Created by 齊藤 洸希 on 2026/06/05.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SensorDataViewModel()
    @State private var showSplashScreen = true
    
    var body: some View {
        ZStack {
            // メイン画面
            TabView {
                SummaryTabView(viewModel: viewModel)
                    .tabItem { Label("概要", systemImage: "doc.text.magnifyingglass") }
                
                GraphTabView(viewModel: viewModel)
                    .tabItem { Label("グラフ", systemImage: "chart.xyaxis.line") }
                
                HistoryTabView(viewModel: viewModel)
                    .tabItem { Label("履歴", systemImage: "list.dash") }
            }
            .opacity(viewModel.isDataLoaded ? 1.0 : 0.0) // 読み込み中は透明に
            
            // スプラッシュ画面（前面に重ねる）
            if showSplashScreen {
                SplashView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                    .zIndex(1)
            }
        }
        .task {
            await viewModel.startFetching()
        }
        .onReceive(viewModel.$isDataLoaded) { isLoaded in
            if isLoaded {
                // 読み込み完了後、0.5秒待ってからアニメーション付きで消す
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showSplashScreen = false
                    }
                }
            }
        }
    }
}
