//
// StateMapView.swift
// Created by Joey Jarosz on 12/14/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import MapKit

/// Interactive map view displaying a US state with highlighting
struct StateMapView: View {

    // MARK: - Properties

    let stateInfo: StateInformation

    @State private var position: MapCameraPosition
    @State private var mapRegion: MKCoordinateRegion

    // MARK: - Initialization

    init(stateInfo: StateInformation) {
        self.stateInfo = stateInfo

        // Create coordinate for state center
        let coordinate = CLLocationCoordinate2D(
            latitude: stateInfo.centerLatitude,
            longitude: stateInfo.centerLongitude
        )

        // Set up map region centered on the state
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
        )

        _mapRegion = State(initialValue: region)
        _position = State(initialValue: .region(region))
    }

    // MARK: - Body

    var body: some View {
        Map(position: $position) {
            // Add a marker for the state capital
            Marker(stateInfo.capital, coordinate: CLLocationCoordinate2D(
                latitude: stateInfo.centerLatitude,
                longitude: stateInfo.centerLongitude
            ))
            .tint(.red)
        }
        .mapStyle(.standard(elevation: .realistic))
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4)
        .accessibilityLabel("Map showing \(stateInfo.stateName) with capital at \(stateInfo.capital)")
    }
}

// MARK: - Preview

#Preview {
    StateMapView(stateInfo: StateInformation(
        stateName: "California",
        capital: "Sacramento",
        stateBird: "California Valley Quail",
        statePlant: "California Poppy",
        centerLatitude: 37.7749,
        centerLongitude: -122.4194
    ))
    .padding()
}
