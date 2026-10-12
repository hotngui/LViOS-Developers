import SwiftUI

extension EnvironmentValues {
    /// The container the dashboard puts its cards in. An enum case, so the default is stable.
    @Entry public var containerStyle: ContainerStyle = .standard
}
