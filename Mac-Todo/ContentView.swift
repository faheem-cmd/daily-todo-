import SwiftUI

struct TodoItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var time: Date // Add a property for time
}

struct ContentView: View {
    @State private var newTodoName = ""
    @State private var todoList: [TodoItem] = []
    @State private var deleteAlertShown = false
    @State private var deleteIndex: Int?
    @State private var selectedTime = Date() // Add a State property for selected time

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor) // Set light theme background

            VStack {
                List {
                    ForEach(todoList) { todo in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(todo.name)
                                    .foregroundColor(.primary)
                                    .font(.headline)
                                    .fontWeight(.medium)

                                Text("\(timeFormatter.string(from: todo.time))") // Display the time along with the text
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                            .padding(.leading) // Add some left padding for better alignment

                            Spacer() // Add a spacer to push the delete button to the right

                            Button(action: {
                                deleteIndex = todoList.firstIndex(of: todo) // Set the index to be deleted
                                deleteAlertShown = true // Show the delete alert
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red) // Set the delete icon color to red
                            }
                            .buttonStyle(BorderlessButtonStyle()) // Remove the button background

                        }
                        .contentShape(Rectangle()) // Make the entire row tappable
                        .onTapGesture {
                            // Optionally, handle tapping on the Todo item here
                        }
                    }
                    .onDelete(perform: deleteTodos) // Use the correct delete function with IndexSet argument
                }
                .listStyle(PlainListStyle()) // Use a plain list style
                .padding() // Add extra padding for better visibility of the list
                .padding(.top, 20) // Add top margin to the listing section

                HStack {
                    TextField("Add Todo", text: $newTodoName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor)) // Use the window background color for better visibility
                        .foregroundColor(.primary) // Set the text color to primary

                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .labelsHidden() // Hide the default label of DatePicker
                        .datePickerStyle(.automatic) // Use the .automatic date picker style
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor)) // Use the window background color for better visibility
                        .foregroundColor(.primary) // Set the text color to primary

                    Button(action: addTodo) {
                        Image(systemName: "plus")
                            .foregroundColor(.black) // Set the foreground color of the "plus" icon to black
                    }
                    .padding()
                    .background(Color.blue) // Set the background color of the button
                    .clipShape(Circle()) // Make it a circle-shaped button

                }
                .padding(.horizontal)
                .padding(.bottom) // Add bottom padding to separate the list from the input area
            }
        }
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $deleteAlertShown) {
            Alert(
                title: Text("Delete Todo"),
                message: Text("Are you sure you want to delete this item?"),
                primaryButton: .destructive(Text("Delete"), action: {
                    if let deleteIndex = deleteIndex {
                        deleteTodos(at: IndexSet(integer: deleteIndex)) // Call delete function with IndexSet argument
                    }
                }),
                secondaryButton: .cancel {
                    deleteIndex = nil // Clear the deleteIndex after dismissing the alert
                }
            )
        }
    }

    func addTodo() {
        let trimmedTodoName = newTodoName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTodoName.isEmpty {
            let newTodo = TodoItem(name: trimmedTodoName, time: selectedTime) // Save the selected time along with the Todo
            todoList.append(newTodo)
            newTodoName = ""
            saveTodoList()
        }
    }

    func deleteTodos(at offsets: IndexSet) {
        todoList.remove(atOffsets: offsets)
        saveTodoList()
    }

    func saveTodoList() {
        if let encodedData = try? JSONEncoder().encode(todoList) {
            UserDefaults.standard.set(encodedData, forKey: "TodoList")
        }
    }
}

// Custom time formatter to display time
fileprivate let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.locale = Locale(identifier: "en_US_POSIX") // Set the locale to use the 12-hour clock format
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
