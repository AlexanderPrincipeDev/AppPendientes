import SwiftUI

struct TodayView: View {
    @EnvironmentObject var model: ChoreModel
    @State private var showingAddTask = false
    @State private var scrollOffset: CGFloat = 0
    
    private var todayTasks: [TaskItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Solo las tareas que realmente corresponden a HOY
        let todayTasksOnly = model.tasks.filter { task in
            // Para tareas diarias: verificar si están activas hoy
            if task.taskType == .daily {
                return model.isTaskActiveToday(task.id)
            }
            // Para tareas específicas: verificar si son exactamente para hoy
            else if task.taskType == .specific, let specificDate = task.specificDate {
                let taskDate = calendar.startOfDay(for: specificDate)
                return taskDate == today
            }
            return false
        }
        
        return todayTasksOnly
    }
    
    private var completedTasks: [TaskItem] {
        todayTasks.filter { model.isTaskCompletedToday($0.id) }
    }
    
    private var pendingTasks: [TaskItem] {
        todayTasks.filter { !model.isTaskCompletedToday($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Enhanced background with gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            // Enhanced Header with better visual hierarchy
                            EnhancedTodayHeaderView()
                                .id("header")
                            
                            // Enhanced Pending tasks section
                            if !pendingTasks.isEmpty {
                                EnhancedTaskSection(
                                    title: "Pendientes",
                                    subtitle: "Tareas por completar",
                                    tasks: pendingTasks,
                                    isCompleted: false,
                                    icon: "clock.fill",
                                    accentColor: .orange
                                )
                            }
                            
                            // Enhanced Completed tasks section
                            if !completedTasks.isEmpty {
                                EnhancedTaskSection(
                                    title: "Completadas",
                                    subtitle: "¡Bien hecho!",
                                    tasks: completedTasks,
                                    isCompleted: true,
                                    icon: "checkmark.circle.fill",
                                    accentColor: .green
                                )
                            }
                            
                            // Enhanced Empty state
                            if todayTasks.isEmpty {
                                EnhancedEmptyTodayView()
                            }
                            
                            // Extra spacing for better scrolling
                            Color.clear.frame(height: 60)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("Hoy")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // Refresh data if needed
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    // Trigger refresh animation
                }
            }
        }
    }
}

// MARK: - Enhanced Today Header
struct EnhancedTodayHeaderView: View {
    @EnvironmentObject var model: ChoreModel
    @State private var isAnimating = false
    
    private var todayRecord: DailyRecord {
        model.todayRecord
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Buenos días"
        case 12..<18: return "Buenas tardes"
        default: return "Buenas noches"
        }
    }
    
    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "sun.max.fill"
        case 12..<18: return "sun.haze.fill"
        default: return "moon.stars.fill"
        }
    }
    
    private var greetingColor: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .orange
        case 12..<18: return .yellow
        default: return .indigo
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Enhanced greeting section
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: greetingIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(greetingColor)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                        
                        Text(greetingText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                    
                    Text(Date().fullDateString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Enhanced progress circle with glow effect
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .blue.opacity(0.2),
                                    .blue.opacity(0.05),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                    
                    // Progress circle background
                    Circle()
                        .stroke(.quaternary.opacity(0.5), lineWidth: 6)
                        .frame(width: 70, height: 70)
                    
                    // Progress circle fill
                    Circle()
                        .trim(from: 0, to: todayRecord.completionRate)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: todayRecord.completionRate)
                    
                    // Percentage text
                    VStack(spacing: 2) {
                        Text("\(Int(todayRecord.completionRate * 100))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text("%")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Enhanced progress section with better visuals
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progreso del día")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Text("Mantén el momentum")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Enhanced statistics
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("\(todayRecord.completedCount)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)
                            
                            Text("Hechas")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 2) {
                            Text("\(todayRecord.totalCount - todayRecord.completedCount)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)
                            
                            Text("Pendientes")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Enhanced progress bar
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.quaternary.opacity(0.5))
                                .frame(height: 8)
                            
                            // Progress fill with gradient
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan, .green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * todayRecord.completionRate, height: 8)
                                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: todayRecord.completionRate)
                        }
                    }
                    .frame(height: 8)
                    
                    // Progress labels
                    HStack {
                        Text("0%")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        
                        Spacer()
                        
                        Text("100%")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.quaternary.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Enhanced Task Section
struct EnhancedTaskSection: View {
    @EnvironmentObject var model: ChoreModel
    let title: String
    let subtitle: String
    let tasks: [TaskItem]
    let isCompleted: Bool
    let icon: String
    let accentColor: Color
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced section header
            Button {
                HapticManager.shared.lightImpact()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Icon with enhanced styling
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Task count badge
                    HStack(spacing: 8) {
                        Text("\(tasks.count)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(accentColor.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 0 : 180))
                    }
                }
                .padding(20)
            }
            .buttonStyle(.plain)
            
            // Tasks list with enhanced animations
            if isExpanded {
                LazyVStack(spacing: 12) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        EnhancedTodayTaskRow(task: task, isCompleted: isCompleted)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: -10)),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05), value: isExpanded)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.quaternary.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Enhanced Today Task Row
struct EnhancedTodayTaskRow: View {
    @EnvironmentObject var model: ChoreModel
    let task: TaskItem
    let isCompleted: Bool
    @State private var isPressed = false
    @State private var justCompleted = false
    
    private var category: TaskCategory? {
        model.getCategoryForTask(task)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced completion button
            Button {
                // Feedback háptico según la acción
                if isCompleted {
                    HapticManager.shared.taskUncompleted()
                } else {
                    HapticManager.shared.taskCompleted()
                }
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    if !isCompleted {
                        justCompleted = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            justCompleted = false
                        }
                    }
                    model.toggle(taskId: task.id)
                }
            } label: {
                ZStack {
                    // Enhanced background with glow
                    Circle()
                        .fill(
                            isCompleted ?
                            LinearGradient(colors: [.green.opacity(0.2), .green.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.gray.opacity(0.1), .gray.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .stroke(isCompleted ? .green.opacity(0.3) : .gray.opacity(0.2), lineWidth: 2)
                        )
                        .scaleEffect(justCompleted ? 1.2 : 1.0)
                        .shadow(color: isCompleted ? .green.opacity(0.3) : .clear, radius: 8)
                    
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isCompleted ? .green : .gray)
                        .scaleEffect(justCompleted ? 1.3 : 1.0)
                }
            }
            .buttonStyle(.plain)
            
            // Enhanced task content
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.system(size: 16, weight: .semibold))
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 10) {
                    if let category = category {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(category.swiftUIColor)
                            
                            Text(category.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(category.swiftUIColor)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(category.swiftUIColor.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(category.swiftUIColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    if isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.green)
                            
                            Text("Completada")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.green.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCompleted ? .green.opacity(0.03) : .clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isCompleted ? Color.green.opacity(0.1) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: justCompleted)
        .onTapGesture {
            withAnimation(.spring(response: 0.2)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Enhanced Empty Today View
struct EnhancedEmptyTodayView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Enhanced animated illustration
            ZStack {
                // Background glow animation
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .orange.opacity(0.15),
                                .yellow.opacity(0.08),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: isAnimating)
                
                // Main icon container
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.1), .yellow.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.orange.opacity(0.3), .yellow.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(isAnimating ? 10 : -10))
            }
            
            // Enhanced text content
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("¡Buen día!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("Tu día está libre de tareas")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 16) {
                    Text("Es momento perfecto para:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    VStack(spacing: 12) {
                        FeatureRow(icon: "plus.circle.fill", text: "Planificar nuevas tareas", color: .blue)
                        FeatureRow(icon: "target", text: "Establecer objetivos", color: .green)
                        FeatureRow(icon: "sparkles", text: "Tomar un descanso merecido", color: .purple)
                    }
                }
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.quaternary.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}
