import Foundation

/// 以独立存储域验证持久化及切换行为，不发起网络请求，也不读写应用的正式配置。
@main
struct TronManagerStateTests {
    @MainActor
    static func main() async throws {
        let suiteName = "TronManagerStateTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestFailure("无法创建临时 UserDefaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let address = "TLHuPCitAKetRjgvkc3YX61nraU3qyifQn"
        let state = StopwatchState(defaults: defaults)
        state.lapTag = address
        state.kind = .split
        state.resultText = "用户手工编辑的结果"

        let restored = StopwatchState(defaults: defaults)
        try expect(restored.lapTag == address, "地址未从临时 suite 恢复")
        try expect(restored.kind == .split, "币种模式未从临时 suite 恢复")
        try expect(restored.resultText == "用户手工编辑的结果", "手工结果文本未恢复")

        restored.lapTag = "TMRyaDePk63uo2MGLJAj3Ki71AfA7CLT4w"
        try expect(restored.resultText.isEmpty, "切换地址后没有清空结果文本")
        restored.resultText = "待清空"
        restored.kind = .lap
        try expect(restored.resultText.isEmpty, "切换币种后没有清空结果文本")

        state.apiKey = "  test-key  "
        try expect(state.apiKey == "test-key", "API Key 未去掉首尾空白")
        let keyRestored = StopwatchState(defaults: defaults)
        try expect(keyRestored.apiKey == "test-key", "API Key 未从临时 suite 恢复")
        keyRestored.apiKey = "   "
        try expect(keyRestored.apiKey.isEmpty, "空白 API Key 未视为清除")
        try expect(defaults.string(forKey: TronAPIKey.storageKey) == nil, "已清除的 API Key 仍被保存")

        restored.resultText = "待清除的查询结果"
        restored.clearResults()
        try expect(restored.resultText.isEmpty, "清除后查询结果文本仍在")

        defaults.set("5201314", forKey: "stopwatch.lastLapTag")
        let unlockCodeState = StopwatchState(defaults: defaults)
        try expect(unlockCodeState.lapTag.isEmpty, "5201314 不应恢复到地址输入框")
        try expect(defaults.string(forKey: "stopwatch.lastLapTag") == nil, "5201314 不应继续持久化")
        print("TronManagerStateTests: ALL CHECKS PASSED")
    }

    private static func expect(_ condition: Bool, _ message: String) throws {
        guard condition else { throw TestFailure(message) }
    }
}

private struct TestFailure: Error, CustomStringConvertible {
    let message: String

    init(_ message: String) { self.message = message }
    var description: String { "测试失败：\(message)" }
}
