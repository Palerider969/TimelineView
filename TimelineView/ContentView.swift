//
//  ContentView.swift
//  TimelineView
//
//  Created by Niklas_Aixsponza on 10.12.24.
//

import SwiftUI

struct Project: Identifiable {
    let id = UUID()
    var description: String
    var startDate: Date
    var endDate: Date
}

class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    
    init() {
        // Add some sample data
        let today = Date()
        projects = [
            Project(description: "Sample Project 3",
                   startDate: today,
                   endDate: Calendar.current.date(byAdding: .day, value: 7, to: today)!),
            Project(description: "Sample Project 2",
                   startDate: Calendar.current.date(byAdding: .day, value: 3, to: today)!,
                   endDate: Calendar.current.date(byAdding: .day, value: 14, to: today)!)
        ]
    }
}

struct ProjectListView: View {
    @Binding var projects: [Project]
    
    var body: some View {
        List {
            ForEach(projects) { project in
                VStack(alignment: .leading) {
                    Text(project.description)
                        .font(.headline)
                    HStack {
                        Text(project.startDate, style: .date)
                        Text("-")
                        Text(project.endDate, style: .date)
                    }
                    .font(.subheadline)
                }
            }
        }
    }
}

struct TimelineView: View {
    let projects: [Project]
    
    private var dateRange: (start: Date, end: Date) {
        let dates = projects.flatMap { [$0.startDate, $0.endDate] }
        guard let minDate = dates.min(),
              let maxDate = dates.max() else {
            let now = Date()
            return (now, Calendar.current.date(byAdding: .day, value: 14, to: now)!)
        }
        
        // Add some padding to the range
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -1, to: minDate)!
        let end = calendar.date(byAdding: .day, value: 1, to: maxDate)!
        return (start, end)
    }
    
    private func xPosition(for date: Date, in geometry: GeometryProxy) -> CGFloat {
        let totalSeconds = dateRange.end.timeIntervalSince(dateRange.start)
        let secondsFromStart = date.timeIntervalSince(dateRange.start)
        return (secondsFromStart / totalSeconds) * geometry.size.width
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // Date markers
                HStack(spacing: 0) {
                    ForEach(0..<7) { i in
                        let date = Calendar.current.date(byAdding: .day,
                                                       value: i * Int((dateRange.end.timeIntervalSince(dateRange.start)) / (60*60*24*6)),
                                                       to: dateRange.start)!
                        Text(dateFormatter.string(from: date))
                            .font(.caption)
                            .frame(width: geometry.size.width / 6)
                    }
                }
                .frame(height: 20)
                
                // Project bars
                ZStack(alignment: .topLeading) {
                    // Background grid
                    HStack(spacing: 0) {
                        ForEach(0..<6) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 1)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Project bars
                    ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                        let startX = xPosition(for: project.startDate, in: geometry)
                        let endX = xPosition(for: project.endDate, in: geometry)
                        let width = endX - startX
                        
                        VStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: max(width, 2), height: 30)
                                .overlay(
                                    Text(project.description)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .padding(.horizontal, 4)
                                )
                        }
                        .position(x: startX + width/2, y: CGFloat(index * 40) + 35)
                    }
                }
            }
            .padding()
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ProjectsViewModel()
    
    var body: some View {
        #if os(macOS)
        HSplitView {
            TimelineView(projects: viewModel.projects)
                .frame(minHeight: 200, maxHeight: .infinity)
            
            ProjectListView(projects: $viewModel.projects)
                .frame(minHeight: 200, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
        #else
        VStack {
            TimelineView(projects: viewModel.projects)
                .frame(minHeight: 200, maxHeight: .infinity)
            
            Divider()
            
            ProjectListView(projects: $viewModel.projects)
                .frame(minHeight: 200, maxHeight: .infinity)
        }
        #endif
    }
}

#Preview {
    ContentView()
}
