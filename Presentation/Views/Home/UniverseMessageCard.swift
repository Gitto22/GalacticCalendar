//
//  UniverseMessageCard.swift
//  GalacticCalendar
//

import SwiftUI

/// Card surface reserved for Universe Messages on the Home screen.
///
/// Presentation shell only. Content, sourcing, and feature gating
/// remain deferred.
struct UniverseMessageCard: View {

    // MARK: - Body

    var body: some View {
        // TODO: Apply the approved Universe Message card layout.
        // TODO: Bind message content through HomeViewModel when the feature is connected.
        // TODO: Respect FeatureFlag.universeMessages before showing content.
        EmptyView()
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Universe Message Card") {
    UniverseMessageCard()
}
#endif
