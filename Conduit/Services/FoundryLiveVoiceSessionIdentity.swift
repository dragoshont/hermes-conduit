import Foundation

enum FoundryLiveVoiceSessionIdentity {
    struct CatalogEntry: Equatable {
        let id: String
        let alternateIDs: [String]
        let profile: String?
    }

    static func canonicalID(
        activeSessionID: String?,
        activeProfile: String,
        catalog: [CatalogEntry],
        identityCanonicalID: String?,
        identityEquivalentIDs: Set<String>
    ) -> String? {
        guard let activeSessionID = normalized(activeSessionID) else { return nil }
        let normalizedProfile = normalized(activeProfile) ?? ""

        if let catalogSession = catalog.first(where: { session in
            let belongsToActiveProfile = session.profile
                .flatMap(normalized)
                .map { $0.caseInsensitiveCompare(normalizedProfile) == .orderedSame }
                ?? true
            return belongsToActiveProfile &&
                (normalized(session.id) == activeSessionID ||
                    session.alternateIDs.compactMap(normalized).contains(activeSessionID))
        }) {
            return normalized(catalogSession.id)
        }

        let equivalents = Set(identityEquivalentIDs.compactMap(normalized))
        guard equivalents.contains(activeSessionID),
              let durableID = normalized(identityCanonicalID),
              durableID != activeSessionID else {
            return nil
        }
        return durableID
    }

    private static func normalized(_ value: String?) -> String? {
        let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return normalized.isEmpty ? nil : normalized
    }
}
