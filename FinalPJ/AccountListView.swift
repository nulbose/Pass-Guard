import SwiftUI
import SwiftData

struct AccountListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.serviceName) private var accounts: [Account]
    @State private var vm = AccountViewModel()
    @State private var search = ""

    private var filtered: [Account] {
        if search.isEmpty { return accounts }
        return accounts.filter {
            $0.serviceName.localizedCaseInsensitiveContains(search) ||
            $0.username.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { account in
                    NavigationLink(destination: DetailView(account: account, vm: vm)) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(scoreColor(account.totalScore).opacity(0.15))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Text(String(account.serviceName.prefix(1)).uppercased())
                                        .font(.headline)
                                        .foregroundStyle(scoreColor(account.totalScore))
                                }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(account.serviceName).font(.body.weight(.medium))
                                Text(account.username).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(account.totalScore)점")
                                .font(.subheadline.bold())
                                .foregroundStyle(scoreColor(account.totalScore))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { idx in
                    for i in idx { vm.deleteAccount(filtered[i], context: context) }
                }
            }
            .searchable(text: $search, prompt: "계정 검색")
            .navigationTitle("계정 목록")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { vm.showAddSheet = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $vm.showAddSheet) {
                AddSheet(vm: vm)
            }
            .overlay {
                if accounts.isEmpty {
                    ContentUnavailableView("등록된 계정 없음", systemImage: "key.fill",
                                           description: Text("+ 버튼을 눌러 계정을 추가하세요"))
                }
            }
        }
    }
}

// MARK: - Add Sheet
struct AddSheet: View {
    @Environment(\.modelContext) private var context
    @Bindable var vm: AccountViewModel
    @State private var showPwd = false

    var body: some View {
        NavigationStack {
            Form {
                Section("계정 정보") {
                    TextField("서비스 이름", text: $vm.serviceName).autocorrectionDisabled()
                    TextField("계정 이름 / 이메일", text: $vm.accountUsername)
                        .autocorrectionDisabled().textInputAutocapitalization(.never)
                }
                Section("비밀번호") {
                    HStack {
                        if showPwd {
                            TextField("비밀번호", text: $vm.accountPassword)
                                .autocorrectionDisabled().textInputAutocapitalization(.never)
                        } else {
                            SecureField("비밀번호", text: $vm.accountPassword)
                                .textContentType(.oneTimeCode)
                        }
                        Button { showPwd.toggle() } label: {
                            Image(systemName: showPwd ? "eye.slash" : "eye").foregroundStyle(.secondary)
                        }
                    }
                    if !vm.accountPassword.isEmpty {
                        let a = PasswordAnalyzer.analyze(vm.accountPassword)
                        let s = max(0, min(100, a.strengthScore - a.patternPenalty + 15))
                        HStack {
                            ProgressView(value: Double(s), total: 100).tint(scoreColor(s))
                            Text("\(s)점").font(.caption.bold()).foregroundStyle(scoreColor(s))
                            Text(s >= 70 ? "안전" : s >= 40 ? "주의" : "위험")
                                .font(.caption.bold()).foregroundStyle(scoreColor(s))
                        }

                        // Strength criteria checklist
                        VStack(alignment: .leading, spacing: 4) {
                            Text("강도 기준").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            criteriaRow("8자 이상", vm.accountPassword.count >= 8)
                            criteriaRow("소문자 포함 (a-z)", vm.accountPassword.range(of: "[a-z]", options: .regularExpression) != nil)
                            criteriaRow("대문자 포함 (A-Z)", vm.accountPassword.range(of: "[A-Z]", options: .regularExpression) != nil)
                            criteriaRow("숫자 포함 (0-9)", vm.accountPassword.range(of: "[0-9]", options: .regularExpression) != nil)
                            criteriaRow("특수문자 포함 (!@#$..)", vm.accountPassword.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil)
                        }

                        // Detected pattern warnings
                        if !a.patterns.isEmpty {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("감지된 문제").font(.caption.weight(.semibold)).foregroundStyle(.red)
                                ForEach(a.patterns, id: \.self) { p in
                                    Label(p, systemImage: "xmark.circle.fill")
                                        .font(.caption2).foregroundStyle(.red)
                                }
                            }
                        }

                        // Improvement tips
                        if s < 70 {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("보완 팁").font(.caption.weight(.semibold)).foregroundStyle(.blue)
                                if vm.accountPassword.count < 12 {
                                    Label("12자 이상으로 늘려보세요", systemImage: "arrow.up.circle").font(.caption2).foregroundStyle(.blue)
                                }
                                if vm.accountPassword.range(of: "[A-Z]", options: .regularExpression) == nil {
                                    Label("대문자를 추가하세요", systemImage: "textformat.abc").font(.caption2).foregroundStyle(.blue)
                                }
                                if vm.accountPassword.range(of: "[0-9]", options: .regularExpression) == nil {
                                    Label("숫자를 추가하세요", systemImage: "number").font(.caption2).foregroundStyle(.blue)
                                }
                                if vm.accountPassword.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil {
                                    Label("특수문자를 추가하세요", systemImage: "asterisk").font(.caption2).foregroundStyle(.blue)
                                }
                                if !a.patterns.isEmpty {
                                    Label("사전 단어나 패턴을 피하세요", systemImage: "shield.slash").font(.caption2).foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                if !vm.errorMessage.isEmpty {
                    Text(vm.errorMessage).foregroundStyle(.red).font(.caption)
                }
            }
            .navigationTitle("계정 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { vm.clearFields() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { vm.addAccount(context: context) }.fontWeight(.semibold)
                }
            }
        }
    }

    private func criteriaRow(_ text: String, _ met: Bool) -> some View {
        Label(text, systemImage: met ? "checkmark.circle.fill" : "circle")
            .font(.caption2)
            .foregroundStyle(met ? .green : .secondary)
    }
}

// MARK: - Detail
struct DetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let account: Account
    @Bindable var vm: AccountViewModel
    @State private var showPwd = false
    @State private var editing = false
    @State private var newPwd = ""
    @State private var pwd: String?
    @State private var showDeleteAlert = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle().stroke(Color(.systemGray5), lineWidth: 12).frame(width: 120, height: 120)
                        Circle().trim(from: 0, to: CGFloat(account.totalScore) / 100)
                            .stroke(scoreColor(account.totalScore), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 120, height: 120).rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text("\(account.totalScore)").font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(scoreColor(account.totalScore))
                            Text("점").font(.caption).foregroundStyle(.secondary)
                        }
                    }.frame(maxWidth: .infinity)
                    Text(PasswordAnalyzer.label(account.totalScore))
                        .font(.headline).foregroundStyle(scoreColor(account.totalScore))
                }.padding(.vertical, 8)
            }

            Section("계정 정보") {
                LabeledContent("서비스", value: account.serviceName)
                LabeledContent("계정", value: account.username)
                LabeledContent("등록일", value: account.createdAt.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("마지막 변경", value: "\(account.daysSinceChange)일 전")
            }

            Section("점수 분석") {
                LabeledContent("강도 점수") { Text("\(account.strengthScore)/60").foregroundStyle(account.strengthScore >= 40 ? .green : .orange) }
                LabeledContent("패턴 감점") { Text("-\(account.patternPenalty)").foregroundStyle(account.patternPenalty > 0 ? .red : .green) }
                LabeledContent("재사용 감점") { Text(account.isReused ? "-20" : "0").foregroundStyle(account.isReused ? .red : .green) }
                LabeledContent("변경 주기") { Text("+\(account.ageScore)").foregroundStyle(account.ageScore >= 20 ? .green : .orange) }
            }

            Section("비밀번호") {
                if let p = pwd, showPwd {
                    HStack {
                        Text(p).font(.system(.body, design: .monospaced))
                        Spacer()
                        Button { UIPasteboard.general.string = p } label: { Image(systemName: "doc.on.doc") }
                    }
                }
                Button { if showPwd { showPwd = false; pwd = nil } else { pwd = vm.getPassword(for: account); showPwd = true }
                } label: { Label(showPwd ? "비밀번호 숨기기" : "비밀번호 보기", systemImage: showPwd ? "eye.slash" : "eye") }
                if editing {
                    SecureField("새 비밀번호", text: $newPwd).textContentType(.oneTimeCode)
                    Button("변경 저장") { guard !newPwd.isEmpty else { return }; vm.updatePassword(account, newPassword: newPwd, context: context); newPwd = ""; editing = false; showPwd = false; pwd = nil }.fontWeight(.semibold)
                } else {
                    Button { editing = true } label: { Label("비밀번호 변경", systemImage: "key.fill") }
                }
            }

            // Scoring criteria guide
            Section("점수 기준 안내") {
                VStack(alignment: .leading, spacing: 6) {
                    guideRow("강도 (0~60점)", "엔트로피 = log₂(문자종류) × 길이로 계산")
                    guideRow("패턴 감점 (최대 -20)", "사전단어 -5 / 치환(Leet) -5 / 키보드패턴 -5 / 순차문자 -3 / 반복 -3 / 편향 -3 / 단어+숫자 -3 / 날짜 -2")
                    guideRow("재사용 감점 (-15)", "다른 계정과 동일한 비밀번호 사용 시")
                    guideRow("변경 주기 (0~15점)", "90일 이내 +15 / 180일 이내 +8 / 초과 +0")
                }
            }

            // Warnings & Improvement tips
            if account.isReused || account.totalScore < 70 || account.daysSinceChange > 90 {
                Section("경고 및 보완 제안") {
                    if account.isReused {
                        Label("다른 계정과 같은 비밀번호 사용 중", systemImage: "exclamationmark.triangle.fill").font(.caption).foregroundStyle(.orange)
                        Label("→ 각 계정마다 고유한 비밀번호를 사용하세요", systemImage: "lightbulb.fill").font(.caption2).foregroundStyle(.blue)
                    }
                    if account.totalScore < 40 {
                        Label("비밀번호 강도가 낮습니다", systemImage: "exclamationmark.shield.fill").font(.caption).foregroundStyle(.red)
                        Label("→ 생성기에서 강력한 비밀번호를 만들어 교체하세요", systemImage: "lightbulb.fill").font(.caption2).foregroundStyle(.blue)
                    }
                    if account.strengthScore < 25 {
                        Label("→ 대문자/숫자/특수문자를 조합하고 12자 이상으로 늘리세요", systemImage: "arrow.up.circle").font(.caption2).foregroundStyle(.blue)
                    }
                    if account.patternPenalty > 0 {
                        Label("예측 가능한 패턴이 감지되었습니다", systemImage: "eye.trianglebadge.exclamationmark").font(.caption).foregroundStyle(.orange)
                        Label("→ 사전 단어, 키보드 패턴(qwerty), 반복 문자를 피하세요", systemImage: "lightbulb.fill").font(.caption2).foregroundStyle(.blue)
                    }
                    if account.daysSinceChange > 90 {
                        Label("90일 이상 변경하지 않았습니다", systemImage: "clock.badge.exclamationmark").font(.caption).foregroundStyle(.orange)
                        Label("→ 정기적으로 비밀번호를 변경하면 +20점을 받을 수 있습니다", systemImage: "lightbulb.fill").font(.caption2).foregroundStyle(.blue)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("계정 삭제", systemImage: "trash")
                }
            }
        }
        .navigationTitle(account.serviceName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("계정 삭제", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                vm.deleteAccount(account, context: context)
                dismiss()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("\(account.serviceName) 계정을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.")
        }
    }

    private func guideRow(_ title: String, _ desc: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption.weight(.semibold))
            Text(desc).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

private func scoreColor(_ score: Int) -> Color {
    if score >= 70 { return .green }
    if score >= 40 { return .yellow }
    return .red
}
