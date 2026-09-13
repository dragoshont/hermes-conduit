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

    func testCatalogOnlyIDIsAcceptedAsDurable() {
        let entry = FoundryLiveVoiceSessionIdentity.CatalogEntry(
            id: "stored-session",
            storedSessionID: nil,
            alternateIDs: [],
            profile: "default"
        )

        XCTAssertEqual(
            FoundryLiveVoiceSessionIdentity.canonicalID(
                activeSessionID: "stored-session",
                activeProfile: "default",
                catalog: [entry],
                identityCanonicalID: nil,
                identityEquivalentIDs: []
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

final class AppStateFoundryLiveVoiceConfigurationTests: XCTestCase {
    func testConfigurationUsesStoredIDFromProductionPayload() {
        MainActor.assumeIsolated {
            let suite = "AppStateFoundryLiveVoiceConfigurationTests.\(UUID().uuidString)"
            guard let defaults = UserDefaults(suiteName: suite) else {
                XCTFail("Failed to create test UserDefaults suite")
                return
            }
            defer { defaults.removePersistentDomain(forName: suite) }

            let appState = AppState(defaults: defaults, loadSavedConnection: false)
            appState.connection = HermesConnection(
                baseUrl: "https://hermes-bakeoff.hont.ro",
                ticket: "test-ticket"
            )
            appState.activeSessionId = "runtime-session"
            XCTAssertNil(appState.foundryLiveVoiceConfiguration)

            appState.sessions = MessageNormalizer.normalizeSessions(
                .object([
                    "sessions": .array([
                        .object([
                            "session_id": .string("runtime-session"),
                            "id": .string("stored-session"),
                            "profile": .string(appState.activeProfile),
                        ])
                    ])
                ]),
                profile: appState.activeProfile
            )

            XCTAssertEqual(appState.sessions.first?.id, "runtime-session")
            XCTAssertEqual(appState.sessions.first?.storedSessionId, "stored-session")
            XCTAssertEqual(
                appState.foundryLiveVoiceConfiguration?.sessionID,
                "stored-session"
            )
        }
    }

    func testConfigurationUsesExactCatalogIDWhenNoAliasExists() {
        MainActor.assumeIsolated {
            let suite = "AppStateFoundryLiveVoiceConfigurationTests.\(UUID().uuidString)"
            guard let defaults = UserDefaults(suiteName: suite) else {
                XCTFail("Failed to create test UserDefaults suite")
                return
            }
            defer { defaults.removePersistentDomain(forName: suite) }

            let appState = AppState(defaults: defaults, loadSavedConnection: false)
            appState.connection = HermesConnection(
                baseUrl: "https://hermes-bakeoff.hont.ro",
                ticket: "test-ticket"
            )
            appState.activeSessionId = "stored-session"
            appState.sessions = MessageNormalizer.normalizeSessions(
                .object([
                    "sessions": .array([
                        .object([
                            "id": .string("stored-session"),
                            "profile": .string(appState.activeProfile),
                        ])
                    ])
                ]),
                profile: appState.activeProfile
            )

            XCTAssertNil(appState.sessions.first?.storedSessionId)
            XCTAssertEqual(
                appState.foundryLiveVoiceConfiguration?.sessionID,
                "stored-session"
            )
        }
    }
}
