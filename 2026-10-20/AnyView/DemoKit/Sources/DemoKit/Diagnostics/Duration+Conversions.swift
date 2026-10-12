extension Duration {
    public var inSeconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1e18
    }

    public var inMilliseconds: Double {
        inSeconds * 1_000
    }
}
