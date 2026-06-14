import SwiftUI
import SwiftData

struct HomeDashboardView: View {
    @Query private var accounts: [Account]

    private var score: Int { PasswordAnalyzer.overallScore(accounts) }
    private var weakCount: Int { accounts.filter { $0.totalScore < 40 }.count }
    private var reusedCount: Int { accounts.filter { $0.isReused }.count }
    private var safeCount: Int { accounts.filter { $0.totalScore >= 70 && !$0.isReused }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Gauge
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 20)
                            .frame(width: 180, height: 180)
                        Circle()
                            .trim(from: 0, to: CGFloat(score) / 100)
                            .stroke(scoreColor(score), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.6), value: score)
                        VStack(spacing: 2) {
                            Text("\(score)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(scoreColor(score))
                            Text("보안 점수")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 20)

                    // Cards
                    HStack(spacing: 12) {
                        StatCard(title: "위험", count: weakCount, icon: "exclamationmark.triangle.fill", color: .red)
                        StatCard(title: "재사용", count: reusedCount, icon: "doc.on.doc.fill", color: .yellow)
                        StatCard(title: "안전", count: safeCount, icon: "checkmark.shield.fill", color: .green)
                    }
                    .padding(.horizontal)

                    // Recent
                    if accounts.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                            Text("계정을 추가하여\n보안 점수를 확인하세요")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 32)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("최근 계정")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(accounts.prefix(5)) { a in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(scoreColor(a.totalScore).opacity(0.15))
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            Text(String(a.serviceName.prefix(1)).uppercased())
                                                .font(.subheadline.bold())
                                                .foregroundStyle(scoreColor(a.totalScore))
                                        }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(a.serviceName).font(.subheadline.weight(.medium))
                                        ProgressView(value: Double(a.totalScore), total: 100)
                                            .tint(scoreColor(a.totalScore))
                                    }
                                    Text("\(a.totalScore)점")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(scoreColor(a.totalScore))
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("PassGuard")
        }
    }
}

private func scoreColor(_ score: Int) -> Color {
    if score >= 70 { return .green }
    if score >= 40 { return .yellow }
    return .red
}

struct StatCard: View {
    let title: String; let count: Int; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            Text("\(count)").font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
