import Foundation

enum FoundryLiveVoiceSessionIdentity {
    struct CatalogEntry: Equatable {
        let id: String
        let storedSessionID: String?
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

        let matchingStoredIDs = Set(catalog.compactMap { session -> String? in
            let belongsToActiveProfile = session.profile
                .flatMap(normalized)
                .map { $0.caseInsensitiveCompare(normalizedProfile) == .orderedSame }
                ?? true
            guard belongsToActiveProfile,
                  normalized(session.id) == activeSessionID ||
                    session.alternateIDs.compactMap(normalized).contains(activeSessionID) else {
                return nil
            }
            return normalized(session.storedSessionID)
        })

        let equivalents = Set(identityEquivalentIDs.compactMap(normalized))
        let establishedIdentity = equivalents.contains(activeSessionID)
            ? normalized(identityCanonicalID)
            : nil
        if let establishedIdentity, establishedIdentity != activeSessionID {
            guard matchingStoredIDs.isEmpty || matchingStoredIDs == [establishedIdentity] else {
                return nil
            }
            return establishedIdentity
        }
        guard matchingStoredIDs.count == 1 else { return nil }
        return matchingStoredIDs.first
    }

    private static func normalized(_ value: String?) -> String? {
        let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return normalized.isEmpty ? nil : normalized
    }
}
