import SwiftUI
import UserNotifications

struct TodoItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var time: Date
    var priority: TodoPriority
}

enum TodoPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct ContentView: View {
    @State private var newTodoName = ""
    @State private var todoList: [TodoItem] = []
    @State private var deleteAlertShown = false
    @State private var deleteIndex: Int?
    @State private var selectedPriority = TodoPriority.medium
    @State private var currentDate = Date()
    @State private var selectedHour = 0
    @State private var selectedMinute = 0
    @State private var isAM = true 

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)

            VStack {
                Picker(selection: $selectedPriority, label: Text("Priority")) {
                    ForEach(TodoPriority.allCases, id: \.self) { priority in
                        Text(priority.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .background(Color(NSColor.windowBackgroundColor))
                .foregroundColor(.primary)

                List {
                    ForEach(todoList) { todo in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(todo.name)
                                    .foregroundColor(.primary)
                                    .font(.headline)
                                    .fontWeight(.medium)

                                Text("\(timeFormatter.string(from: todo.time))")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: true, vertical: true)
                            }
                            .padding(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Spacer()

                            Text(todo.priority.rawValue)
                                .foregroundColor(priorityColor(for: todo.priority))
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .center)

                            Spacer()

                            Button(action: {
                                deleteIndex = todoList.firstIndex(of: todo)
                                deleteAlertShown = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Optionally, handle tapping on the Todo item here
                        }
                    }
                    .onDelete(perform: deleteTodos)
                }
                .listStyle(PlainListStyle())
                .padding()
                .padding(.top, 20)

                HStack {
                    TextField("Add Todo", text: $newTodoName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor))
                        .foregroundColor(.primary)
                    
                    Text(formattedDate)
                    
                    HStack {
                        Picker("", selection: $selectedHour) {
                            ForEach(1..<13, id: \.self) { hour in
                                Text(String(format: "%02d", hour))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 60)

                        Text(":")
                            .foregroundColor(.primary)

                        Picker("", selection: $selectedMinute) {
                            ForEach(0..<60, id: \.self) { minute in
                                Text(String(format: "%02d", minute))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 60)
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor))
                    .foregroundColor(.primary)

                    // New AM/PM dropdown
                    Picker("", selection: $isAM) {
                        Text("AM").tag(true)
                        Text("PM").tag(false)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 60)

                    Button(action: addTodo) {
                        Image(systemName: "plus")
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.blue)
                    .clipShape(Circle())

                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $deleteAlertShown) {
            Alert(
                title: Text("Delete Todo"),
                message: Text("Are you sure you want to delete this item?"),
                primaryButton: .destructive(Text("Delete"), action: {
                    if let deleteIndex = deleteIndex {
                        deleteTodos(at: IndexSet(integer: deleteIndex))
                    }
                }),
                secondaryButton: .cancel {
                    deleteIndex = nil
                }
            )
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
                // Handle user authorization response if needed
            }
            loadTodoList()
        }
        .onDisappear {
            saveTodoList()
        }
    }

    func addTodo() {
        let trimmedTodoName = newTodoName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTodoName.isEmpty {
            var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
            components.hour = selectedHour + (isAM ? 0 : 12) // Convert to 24-hour format if PM
            components.minute = selectedMinute
            components.second = 0
            components.timeZone = TimeZone.current // Use the current time zone
            guard let selectedTime = Calendar.current.date(from: components) else {
                return
            }
            let newTodo = TodoItem(name: trimmedTodoName, time: selectedTime, priority: selectedPriority)
            todoList.append(newTodo)
            newTodoName = ""
            scheduleReminder(for: newTodo)
        }
    }

    func deleteTodos(at offsets: IndexSet) {
        for offset in offsets {
            let todo = todoList[offset]
            cancelReminder(for: todo)
        }
        todoList.remove(atOffsets: offsets)
    }

    func saveTodoList() {
        if let encodedData = try? JSONEncoder().encode(todoList) {
            UserDefaults.standard.set(encodedData, forKey: "TodoList")
        }
    }

    func loadTodoList() {
        if let data = UserDefaults.standard.data(forKey: "TodoList") {
            if let decodedTodoList = try? JSONDecoder().decode([TodoItem].self, from: data) {
                todoList = decodedTodoList
            }
        }
    }

    func scheduleReminder(for todo: TodoItem) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "Todo: \(todo.name)"
        content.sound = UNNotificationSound.default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: todo.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: todo.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(for todo: TodoItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [todo.id.uuidString])
    }

    private func priorityColor(for priority: TodoPriority) -> Color {
        switch priority {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // 12-hour format
        return formatter
    }

    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, d, yyyy"
        return dateFormatter.string(from: currentDate)
    }
}

