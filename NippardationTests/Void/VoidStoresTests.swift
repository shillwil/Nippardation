//
//  VoidStoresTests.swift
//  NippardationTests
//
//  ReceivedPlansStore, TodayOverrideStore, BodyWeightStore and ReceivedPlan mapping.
//

import Testing
import Foundation
@testable import Nippardation

@Suite("Void stores")
@MainActor
struct VoidStoresTests {

    // MARK: - ReceivedPlansStore

    private func receivedPlan(token: String, isRead: Bool = false, receivedAt: Date = VoidFixtures.now) -> ReceivedPlan {
        ReceivedPlan(
            token: token,
            type: "program",
            name: "Upper / Lower",
            sharedByName: "Marcus",
            dayCount: 4,
            estimatedMinutes: 60,
            durationWeeks: 8,
            receivedAt: receivedAt,
            isRead: isRead
        )
    }

    @Test func savesMarksReadAndRemoves() {
        let defaults = VoidFixtures.defaults()
        let store = ReceivedPlansStore(defaults: defaults, userIdProvider: { "u1" })

        store.save(receivedPlan(token: "a"))
        store.save(receivedPlan(token: "b", receivedAt: VoidFixtures.daysAgo(1)))
        #expect(store.plans.map(\.token) == ["a", "b"])
        #expect(store.unreadCount == 2)
        #expect(store.hasUnread)

        store.markRead(token: "a")
        #expect(store.unreadCount == 1)
        #expect(store.plan(token: "a")?.isRead == true)

        store.remove(token: "b")
        #expect(store.plans.count == 1)
        #expect(store.contains(token: "b") == false)

        // Persisted: a fresh store over the same defaults sees the same state
        let reloaded = ReceivedPlansStore(defaults: defaults, userIdProvider: { "u1" })
        #expect(reloaded.plans.map(\.token) == ["a"])
        #expect(reloaded.unreadCount == 0)
    }

    @Test func savingAgainKeepsReadStateAndReceivedDate() {
        let store = ReceivedPlansStore(defaults: VoidFixtures.defaults(), userIdProvider: { "u1" })
        let first = receivedPlan(token: "a", receivedAt: VoidFixtures.daysAgo(3))
        store.save(first)
        store.markRead(token: "a")
        store.save(receivedPlan(token: "a", receivedAt: VoidFixtures.now))
        #expect(store.plans.count == 1)
        #expect(store.plan(token: "a")?.isRead == true)
        #expect(store.plan(token: "a")?.receivedAt == first.receivedAt)
    }

    @Test func plansAreScopedPerUser() {
        let defaults = VoidFixtures.defaults()
        let alice = ReceivedPlansStore(defaults: defaults, userIdProvider: { "alice" })
        alice.save(receivedPlan(token: "a"))
        let bob = ReceivedPlansStore(defaults: defaults, userIdProvider: { "bob" })
        #expect(bob.plans.isEmpty)
    }

    @Test func receivedPlanCaptionAndReadout() {
        let plan = receivedPlan(token: "a", receivedAt: VoidFixtures.now)
        #expect(plan.caption(now: VoidFixtures.now) == "4 days · ~60 min · today")
        #expect(plan.readout == "4 DAYS · ~60 MIN · 8 WEEKS")
        #expect(plan.isProgram)
    }

    @Test func receivedPlanMapsFromASharedProgram() {
        let program = VoidFixtures.pplProgram()
        let item = SharedItem(
            token: "tok",
            type: .program,
            sharedBy: SharedItem.SharedBy(handle: "marcus", displayName: "Marcus", avatarUrl: nil),
            sharedAt: VoidFixtures.now,
            template: nil,
            program: program
        )
        let plan = ReceivedPlan(item: item, receivedAt: VoidFixtures.now)
        #expect(plan.token == "tok")
        #expect(plan.name == "The OG")
        #expect(plan.sharedByName == "Marcus")
        #expect(plan.dayCount == 3)
        #expect(plan.durationWeeks == 8)
        #expect(plan.estimatedMinutes != nil)
        #expect(plan.isRead == false)
    }

    @Test func receivedPlanMapsFromASharedTemplate() {
        let template = VoidFixtures.template("Push", serverId: "t", exercises: [VoidFixtures.templateExercise("Bench Press")])
        let item = SharedItem(
            token: "tok",
            type: .template,
            sharedBy: SharedItem.SharedBy(handle: "dee", displayName: nil, avatarUrl: nil),
            sharedAt: VoidFixtures.now,
            template: template,
            program: nil
        )
        let plan = ReceivedPlan(item: item)
        #expect(plan.sharedByName == "dee")
        #expect(plan.dayCount == 1)
        #expect(plan.isProgram == false)
        #expect(plan.readout.hasPrefix("1 WORKOUT"))
    }

    // MARK: - TodayOverrideStore

    @Test func overrideIsScopedToTheDay() {
        let defaults = VoidFixtures.defaults()
        let calendar = VoidFixtures.calendar
        let store = TodayOverrideStore(defaults: defaults, calendar: calendar, userIdProvider: { "u1" })

        store.set(.template(serverId: "t_pull"), on: VoidFixtures.now)
        #expect(store.override == .template(serverId: "t_pull"))
        #expect(store.override?.templateServerId == "t_pull")

        store.refresh(now: VoidFixtures.now)
        #expect(store.override == .template(serverId: "t_pull"))

        // Next day: the override is dropped and the record cleared
        store.refresh(now: VoidFixtures.date(2026, 9, 10))
        #expect(store.override == nil)
        #expect(defaults.data(forKey: "void.todayOverride.u1") == nil)
    }

    @Test func restOverrideAndClear() {
        let store = TodayOverrideStore(defaults: VoidFixtures.defaults(), calendar: VoidFixtures.calendar, userIdProvider: { "u1" })
        store.set(.rest, on: VoidFixtures.now)
        #expect(store.override?.isRest == true)
        store.clear()
        #expect(store.override == nil)
    }

    @Test func dayKeyFormat() {
        #expect(TodayOverrideRecord.dayKey(for: VoidFixtures.date(2026, 9, 8), calendar: VoidFixtures.calendar) == "2026-09-08")
    }

    // MARK: - BodyWeightStore

    @Test func logsWeightAndComputesDelta() {
        let defaults = VoidFixtures.defaults()
        let store = BodyWeightStore(defaults: defaults, userIdProvider: { "u1" })
        #expect(store.latest == nil)
        #expect(store.delta == nil)

        store.log(pounds: 183.0, date: VoidFixtures.daysAgo(2))
        store.log(pounds: 182.4, date: VoidFixtures.now)
        #expect(store.latest?.pounds == 182.4)
        #expect(store.previous?.pounds == 183.0)
        #expect(abs((store.delta ?? 0) - (-0.6)) < 0.0001)

        store.log(pounds: -5)   // ignored
        store.log(pounds: .nan) // ignored
        #expect(store.entries.count == 2)

        let reloaded = BodyWeightStore(defaults: defaults, userIdProvider: { "u1" })
        #expect(reloaded.entries.count == 2)

        if let latest = reloaded.latest {
            reloaded.delete(id: latest.id)
        }
        #expect(reloaded.latest?.pounds == 183.0)
    }
}
