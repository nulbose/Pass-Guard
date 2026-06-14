import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Bindable var settingsVM: SettingsViewModel
    @Bindable var authVM: AuthViewModel

    @State private var exportDoc: JSONDoc?
    @State private var showExport = false
    @State private var showImport = false
    @State private var importMsg = ""
    @State private var showDeleteUserAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Circle().fill(.blue.opacity(0.15)).frame(width: 50, height: 50)
                            .overlay { Image(systemName: "person.fill").font(.title2).foregroundStyle(.blue) }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authVM.username).font(.headline)
                            Text("PassGuard 사용자").font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 4)
                }

                Section("변경 주기 알림") {
                    Toggle("비밀번호 변경 알림", isOn: $settingsVM.reminderOn).tint(.blue)
                    if settingsVM.reminderOn {
                        Picker("변경 주기", selection: $settingsVM.intervalDays) {
                            Text("30일").tag(30); Text("60일").tag(60); Text("90일").tag(90)
                        }.pickerStyle(.segmented)
                    }
                }

                Section("데이터 관리") {
                    Button { if let d = settingsVM.exportJSON(context: context) { exportDoc = JSONDoc(data: d); showExport = true } }
                    label: { Label("데이터 내보내기 (JSON)", systemImage: "square.and.arrow.up") }

                    Button { showImport = true }
                    label: { Label("데이터 가져오기", systemImage: "square.and.arrow.down") }

                    if !importMsg.isEmpty {
                        Text(importMsg).font(.caption).foregroundStyle(.green)
                    }
                }

                Section {
                    Button(role: .destructive) { settingsVM.showDeleteAlert = true }
                    label: { Label("모든 데이터 삭제", systemImage: "trash.fill").foregroundStyle(.red) }
                } footer: { Text("모든 계정 정보와 비밀번호가 영구 삭제됩니다.") }

                Section {
                    Button(role: .destructive) { authVM.logout() }
                    label: { HStack { Spacer(); Text("로그아웃").fontWeight(.semibold); Spacer() } }

                    Button(role: .destructive) { showDeleteUserAlert = true }
                    label: { HStack { Spacer(); Text("계정 탈퇴").fontWeight(.semibold); Spacer() } }
                }

            }
            .navigationTitle("설정")
            .alert("데이터 삭제", isPresented: $settingsVM.showDeleteAlert) {
                Button("삭제", role: .destructive) { settingsVM.deleteAll(context: context) }
                Button("취소", role: .cancel) { }
            } message: { Text("모든 계정 데이터를 삭제하시겠습니까?") }
            .alert("계정 탈퇴", isPresented: $showDeleteUserAlert) {
                Button("탈퇴", role: .destructive) {
                    settingsVM.deleteAll(context: context)
                    authVM.deleteUser()
                }
                Button("취소", role: .cancel) { }
            } message: { Text("계정을 탈퇴하시겠습니까?\n모든 데이터와 로그인 정보가 영구 삭제됩니다.") }
            .fileExporter(isPresented: $showExport, document: exportDoc, contentType: .json,
                          defaultFilename: "passguard_export.json") { r in if case .success = r { importMsg = "내보내기 완료!" } }
            .fileImporter(isPresented: $showImport, allowedContentTypes: [.json]) { r in
                if case .success(let url) = r {
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url) {
                        let n = settingsVM.importJSON(data, context: context)
                        importMsg = "\(n)개 계정을 가져왔습니다."
                    }
                }
            }
        }
    }
}
