import XCTest
@testable import Conduit

final class FoundryLiveVoiceSessionIdentityTests: XCTestCase {
    func testRuntimeOnlyIdentityFailsClosed() {
        XCTAssertNil(
            FoundryLiveVoiceSessionIdentity.canonicalID(
                activeSessionID: "runtime-session",
                activeProfile: "default",
                catalog: [],
                identityCanonicalID: "runtime-session",
                identityEquivalentIDs: ["runtime-session"]
            )
        )
    }

    func testProductionCatalogShapeUsesStoredSessionID() {
        let entry = FoundryLiveVoiceSessionIdentity.CatalogEntry(
            id: "runtime-session",
            storedSessionID: "stored-session",
            alternateIDs: ["stored-session"],
            profile: "default"
        )

        XCTAssertEqual(
            FoundryLiveVoiceSessionIdentity.canonicalID(
                activeSessionID: "runtime-session",
                activeProfile: "default",
                catalog: [entry],
                identityCanonicalID: "runtime-session",
                identityEquivalentIDs: ["runtime-session"]
            ),
            "stored-session"
        )
    }

    func testConflictingStoredIDsFailClosedRegardlessOfRowOrder() {
        let first = entry(storedID: "stored-a", alternateID: "stored-b")
        let second = entry(storedID: "stored-b", alternateID: "stored-a")

        for rows in [[first, second], [second, first]] {
            XCTAssertNil(
                FoundryLiveVoiceSessionIdentity.canonicalID(
                    activeSessionID: "runtime-session",
                    activeProfile: "default",
                    catalog: rows,
                    identityCanonicalID: nil,
                    identityEquivalentIDs: []
                )
            )
        }
    }

    private func entry(
        storedID: String,
        alternateID: String
    ) -> FoundryLiveVoiceSessionIdentity.CatalogEntry {
        .init(
            id: "runtime-session",
            storedSessionID: storedID,
            alternateIDs: [alternateID],
            profile: "default"
        )
    }
}
