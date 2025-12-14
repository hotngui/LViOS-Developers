//
// StateInformationView.swift
// Created by Joey Jarosz on 12/14/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

/// Displays comprehensive information about a US state
struct StateInformationView: View {

    // MARK: - Properties

    let stateInfo: StateInformation

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // State Name Header
                Text(stateInfo.stateName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Map View
                StateMapView(stateInfo: stateInfo)

                // Information Cards
                VStack(spacing: 16) {
                    InfoCard(
                        icon: "building.columns.fill",
                        title: "Capital",
                        value: stateInfo.capital,
                        color: .blue
                    )

                    if let bird = stateInfo.stateBird {
                        InfoCard(
                            icon: "bird.fill",
                            title: "State Bird",
                            value: bird,
                            color: .orange
                        )
                    } else {
                        InfoCard(
                            icon: "bird.fill",
                            title: "State Bird",
                            value: "Information not available",
                            color: .gray
                        )
                    }

                    if let plant = stateInfo.statePlant {
                        InfoCard(
                            icon: "leaf.fill",
                            title: "State Plant",
                            value: plant,
                            color: .green
                        )
                    } else {
                        InfoCard(
                            icon: "leaf.fill",
                            title: "State Plant",
                            value: "Information not available",
                            color: .gray
                        )
                    }
                }
            }
            .padding()
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Info Card Component

/// Reusable card component for displaying state information
struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Preview

#Preview {
    StateInformationView(stateInfo: StateInformation(
        stateName: "California",
        capital: "Sacramento",
        stateBird: "California Valley Quail",
        statePlant: "California Poppy",
        centerLatitude: 37.7749,
        centerLongitude: -122.4194
    ))
}
