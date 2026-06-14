import SwiftUI

struct PasswordGeneratorView: View {
    @State private var vm = PasswordGeneratorViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Result
                    VStack(spacing: 10) {
                        if vm.generated.isEmpty {
                            Text("아래 버튼을 눌러\n비밀번호를 생성하세요")
                                .font(.subheadline).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center).frame(height: 50)
                        } else {
                            Text(vm.generated)
                                .font(.system(.title3, design: .monospaced).weight(.medium))
                                .multilineTextAlignment(.center)
                                .textSelection(.enabled)

                            HStack(spacing: 8) {
                                ProgressView(value: Double(vm.score), total: 100)
                                    .tint(genColor(vm.score))
                                Text("\(vm.score)점").font(.caption.bold()).foregroundStyle(genColor(vm.score))
                                Text(vm.score >= 70 ? "안전" : vm.score >= 40 ? "주의" : "위험")
                                    .font(.caption.bold()).foregroundStyle(genColor(vm.score))
                            }

                            // Security level message
                            Text(vm.securityLevel)
                                .font(.caption2).foregroundStyle(genColor(vm.score))

                            // Crack time
                            HStack(spacing: 4) {
                                Image(systemName: "clock.badge.checkmark")
                                    .font(.caption2).foregroundStyle(.secondary)
                                Text("예상 해독 시간: \(vm.crackTimeText)")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .padding(.top, 16)

                    // Presets
                    VStack(alignment: .leading, spacing: 10) {
                        Text("빠른 설정").font(.headline)
                        HStack(spacing: 10) {
                            ForEach(PasswordGeneratorViewModel.Preset.allCases, id: \.self) { preset in
                                Button {
                                    withAnimation { vm.applyPreset(preset) }
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: preset.icon)
                                            .font(.title3)
                                        Text(preset.rawValue)
                                            .font(.caption.weight(.medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(.systemGray6))
                                    .foregroundStyle(.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Controls
                    VStack(spacing: 18) {
                        HStack {
                            Text("길이").font(.headline)
                            Spacer()
                            Text("\(Int(vm.length))자").font(.headline).foregroundStyle(.blue)
                        }
                        Slider(value: $vm.length, in: 4...20, step: 1).tint(.blue)
                        HStack {
                            Text("4").font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Text("20").font(.caption2).foregroundStyle(.secondary)
                        }

                        Divider()

                        Toggle("소문자 (a-z)", isOn: Binding(
                            get: { vm.useLowercase },
                            set: { newVal in if newVal || vm.canToggleOff { vm.useLowercase = newVal } }
                        )).tint(.blue)
                        Toggle("대문자 (A-Z)", isOn: Binding(
                            get: { vm.useUppercase },
                            set: { newVal in if newVal || vm.canToggleOff { vm.useUppercase = newVal } }
                        )).tint(.blue)
                        Toggle("숫자 (0-9)", isOn: Binding(
                            get: { vm.useNumbers },
                            set: { newVal in if newVal || vm.canToggleOff { vm.useNumbers = newVal } }
                        )).tint(.blue)
                        Toggle("특수문자 (!@#$...)", isOn: Binding(
                            get: { vm.useSpecial },
                            set: { newVal in if newVal || vm.canToggleOff { vm.useSpecial = newVal } }
                        )).tint(.blue)

                        Divider()

                        Toggle("혼동 문자 제외 (l, I, 1, O, 0)", isOn: $vm.excludeAmbiguous).tint(.blue)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    .padding(.horizontal)

                    // Buttons
                    VStack(spacing: 12) {
                        Button { withAnimation { vm.generate() } } label: {
                            Label("비밀번호 생성", systemImage: "wand.and.stars")
                                .fontWeight(.semibold).frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.blue).foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        if !vm.generated.isEmpty {
                            Button { vm.copy() } label: {
                                Label(vm.copied ? "복사됨!" : "클립보드에 복사", systemImage: vm.copied ? "checkmark" : "doc.on.doc")
                                    .fontWeight(.semibold).frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(vm.copied ? .green : Color(.systemGray5))
                                    .foregroundStyle(vm.copied ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Analysis Info
                    if !vm.generated.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("분석 정보").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            infoRow("엔트로피", String(format: "%.1f bits", vm.analysis.entropy))
                            infoRow("강도 점수", "\(vm.analysis.strengthScore) / 60")
                            infoRow("패턴 감점", "-\(vm.analysis.patternPenalty)")
                            infoRow("예상 해독 시간", vm.crackTimeText)

                            if !vm.analysis.patterns.isEmpty {
                                Divider()
                                Text("감지된 패턴").font(.caption.weight(.semibold)).foregroundStyle(.red)
                                ForEach(vm.analysis.patterns, id: \.self) { p in
                                    Label(p, systemImage: "xmark.circle.fill")
                                        .font(.caption2).foregroundStyle(.red)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                        // Tips
                        VStack(alignment: .leading, spacing: 6) {
                            Text("보안 팁").font(.caption.weight(.semibold)).foregroundStyle(.blue)
                            tipRow("대소문자 + 숫자 + 특수문자를 모두 포함하면 가장 강력합니다")
                            tipRow("12자 이상이면 대부분의 무차별 대입 공격에 안전합니다")
                            tipRow("사전 단어나 생년월일을 포함하지 마세요")
                            tipRow("계정마다 서로 다른 비밀번호를 사용하세요")
                        }
                        .padding(16)
                        .background(Color.blue.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("비밀번호 생성기")
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption.weight(.medium))
        }
    }

    private func tipRow(_ text: String) -> some View {
        Label(text, systemImage: "lightbulb.fill")
            .font(.caption2).foregroundStyle(.blue)
    }
}

private func genColor(_ score: Int) -> Color {
    if score >= 70 { return .green }
    if score >= 40 { return .yellow }
    return .red
}
