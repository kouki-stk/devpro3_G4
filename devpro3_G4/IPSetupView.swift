//
//  IPSetupView.swift
//  devpro3_G4
//
//  Created by 齊藤 洸希 on 2026/06/17.
//

import SwiftUI
import LocalAuthentication

struct IPSetupView: View {
    @ObservedObject var viewModel: SensorDataViewModel
    @Binding var currentStep: AppStep
    
    @State private var inputIP: String = UserDefaults.standard.string(forKey: "saved_flask_ip") ?? ""
    @State private var ipHistory: [String] = UserDefaults.standard.stringArray(forKey: "flask_ip_history") ?? []
    @State private var isHistoryUnlocked = false
    @State private var errorMessage: String? = nil
    @State private var isConnecting = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // --- 入力セクション ---
                VStack(spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        TextField("10.192.139.1", text: $inputIP)
                            .font(.system(size: 32, weight: .light, design: .rounded))
                            // ▼ 修正：ドット(.)が打てる数字テンキーに変更
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 240)
                        
                        Text(":5001")
                            .font(.system(size: 22, weight: .light, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Flask サーバーのIPアドレスを入力")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                // --- 接続ボタン ---
                Button(action: { connectToServer(ip: inputIP) }) {
                    if isConnecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("接続")
                            .font(.body)
                            .fontWeight(.medium)
                            // ▼ 修正：ダークモードでも必ず文字が見えるように、背景の逆色を指定
                            .foregroundColor(Color(UIColor.systemBackground))
                            .frame(maxWidth: 140)
                            .padding(.vertical, 12)
                            .background(inputIP.isEmpty ? Color.gray : Color.primary)
                            .cornerRadius(24)
                    }
                }
                .disabled(inputIP.isEmpty || isConnecting)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                // --- 履歴セクション ---
                VStack(spacing: 12) {
                    if isHistoryUnlocked {
                        if ipHistory.isEmpty {
                            Text("履歴はありません")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("履歴から選択")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(ipHistory, id: \.self) { historyIP in
                                        Button(action: {
                                            inputIP = historyIP
                                            connectToServer(ip: historyIP)
                                        }) {
                                            Text(historyIP)
                                                .font(.system(.subheadline, design: .rounded))
                                                .monospacedDigit()
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                                .cornerRadius(16)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    } else {
                        // ▼ 修正：Liquidglass（すりガラス）風の美しいボタンに変更
                        Button(action: authenticateUser) {
                            Text("履歴を表示")
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                // ultraThinMaterial ですりガラス効果を適用
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("サーバー設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "IPアドレスの履歴を安全に表示するために認証が必要です。"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.sync {
                    if success {
                        withAnimation(.easeOut) {
                            isHistoryUnlocked = true
                        }
                    } else {
                        errorMessage = "認証に失敗しました"
                    }
                }
            }
        } else {
            isHistoryUnlocked = true
        }
    }
    
    private func connectToServer(ip: String) {
        guard !ip.isEmpty else { return }
        isConnecting = true
        errorMessage = nil
        
        UserDefaults.standard.set(ip, forKey: "saved_flask_ip")
        
        Task {
            viewModel.isDataLoaded = false
            await viewModel.startFetching()
            
            if viewModel.isDataLoaded {
                var currentHistory = ipHistory
                if let index = currentHistory.firstIndex(of: ip) {
                    currentHistory.remove(at: index)
                }
                currentHistory.insert(ip, at: 0)
                if currentHistory.count > 5 { currentHistory.removeLast() }
                
                UserDefaults.standard.set(currentHistory, forKey: "flask_ip_history")
                
                withAnimation(.linear(duration: 0.3)) {
                    currentStep = .mainUI
                }
            } else {
                errorMessage = "サーバーへの接続に失敗しました。IPを確認してください。"
            }
            isConnecting = false
        }
    }
}
