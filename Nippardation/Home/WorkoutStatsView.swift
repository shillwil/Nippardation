//
//  WorkoutStatsView.swift
//  Nippardation
//
//  Created by Alex Shillingford on 5/18/25.
//

import SwiftUI
import Charts

struct VolumeDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Double
}

struct WorkoutStatsView: View {
    @ObservedObject var workoutManager = WorkoutManager.shared
    @State private var timeRange: TimeRange = .month
    @State private var volumeData: [VolumeDataPoint] = []
    @State private var isRefreshing: Bool = false
    @State private var volumeUnit: VolumeUnit = .pounds
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Workout Volume")
                    .font(.headline)
                
                Spacer()
                
                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            
            // Debug info
            Text("Completed workouts: \(workoutManager.completedWorkouts.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if volumeData.isEmpty {
                Text("No workout data for this period")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                // Chart with simpler date handling
                Chart {
                    ForEach(volumeData) { item in
                        BarMark(
                            x: .value("Date", formatDateForDisplay(item.date)),
                            y: .value("Volume", item.volume)
                        )
                        .foregroundStyle(Color.appTheme.gradient)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: .automatic(includesZero: true))
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                
                // Stats summary
                HStack(spacing: 20) {
                    statBox(value: getTotalVolume(), label: "Total Volume")
                        .onTapGesture {
                            volumeUnit = volumeUnit.next()
                        }
                    statBox(value: "\(volumeData.count)", label: "Workouts")
                    if let avg = getAverageVolume() {
                        statBox(value: avg, label: "Avg Volume")
                            .onTapGesture {
                                volumeUnit = volumeUnit.next()
                            }
                    }
                }
                .padding(.top, 8)
            }
            
            // Improved refresh button
            Button {
                performRefresh()
            } label: {
                HStack {
                    Text("Refresh Chart Data")
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
            .font(.caption)
            .padding(.top, 4)
            .disabled(isRefreshing)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .onAppear {
            performRefresh()
        }
        .onChange(of: timeRange) { _ in
            performRefresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutDataUpdated"))) { _ in
            performRefresh()
        }
    }
    
    private func performRefresh() {
        isRefreshing = true
        
        // Force the WorkoutManager to reload its data
        workoutManager.loadCompletedWorkouts()
        
        // Small delay to ensure data is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            refreshData()
            isRefreshing = false
        }
    }
    
    // Helper to format dates in a consistent way for display
    private func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch timeRange {
        case .week:
            formatter.dateFormat = "EEE"  // Mon, Tue, etc.
        case .month:
            formatter.dateFormat = "d MMM" // 15 May, etc.
        case .year:
            formatter.dateFormat = "MMM" // Jan, Feb, etc.
        }
        
        return formatter.string(from: date)
    }
    
    private func refreshData() {
        // Get raw data
        let rawData = workoutManager.getVolumeData(for: timeRange.days)
        
        // Transform and save to state
        volumeData = rawData.map { VolumeDataPoint(date: $0.date, volume: $0.volume) }
    }
    
    private func getTotalVolume() -> String {
        let totalVolume = volumeData.reduce(0) { $0 + $1.volume }
        return formatWeight(totalVolume)
    }
    
    private func getAverageVolume() -> String? {
        guard !volumeData.isEmpty else { return nil }
        
        let totalVolume = volumeData.reduce(0) { $0 + $1.volume }
        let averageVolume = totalVolume / Double(volumeData.count)
        return formatWeight(averageVolume)
    }
    
    private func formatWeight(_ weight: Double) -> String {
        let convertedWeight = volumeUnit.convert(weight, from: .pounds)
        
        if volumeUnit == .pyramidBlocks || volumeUnit == .pyramids {
            return volumeUnit.formatWithNewline(convertedWeight)
        } else if convertedWeight >= 1000 {
            return String(format: "%.1fK \(volumeUnit.rawValue)", convertedWeight / 1000)
        } else {
            return volumeUnit.formatWithNewline(convertedWeight)
        }
    }
    
    @ViewBuilder
    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(height: 44)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 90, maxWidth: .infinity, minHeight: 80, maxHeight: 80)
        .padding(.horizontal, 4)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    WorkoutStatsView()
}
