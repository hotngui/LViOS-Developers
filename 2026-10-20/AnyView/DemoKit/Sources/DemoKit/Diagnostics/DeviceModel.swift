import Foundation

/// The hardware model identifier (for example `iPhone18,1`), shown on the HUD so every capture documents its device.
public enum DeviceModel {
    public static let identifier: String = {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return "\(simulated) (Simulator)"
        }
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var buffer = [UInt8](repeating: 0, count: size)
        sysctlbyname("hw.machine", &buffer, &size, nil, 0)
        return String(validating: buffer.prefix { $0 != 0 }, as: UTF8.self) ?? "Unknown device"
    }()
}
