import SwiftUI

 struct ContentView: View {
    
    @StateObject private var viewModel = TaskViewModel()
    @State private var showSheet = false
    @State private var newTaskTitle = ""
    
    var activeTasksCount: Int {
        viewModel.tasks.filter { !$0.isComplete }.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack {
                    ScrollView {
                        ForEach(viewModel.tasks) { task in
                            makeCell(for: task)
                        }
                    }
                    .padding(16)
                    .toolbarBackground(Color.white, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Мои задачи")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("\(activeTasksCount) активных задач")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 50)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Button(action: {
                        self.showSheet = true
                    }) {
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(Color.blue)
                            .overlay {
                                Text("+ Новая задача")
                                    .foregroundColor(.white)
                            }
                    }
                    .frame(height: 68)
                    .padding(.horizontal, 16)
                    .sheet(isPresented: $showSheet) {
                        addSheetView
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var addSheetView: some View {
        VStack {
            Section {
                HStack {
                    Text("Новая задача")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: {
                        showSheet = false
                        newTaskTitle = ""
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(.horizontal, 45)
            
            Divider()
                .padding(.vertical, 15)
            
            Section {
                VStack {
                    TextField("Название задачи", text: $newTaskTitle)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .padding(.horizontal, 15)
                        .background(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 4)
                        )
                        .cornerRadius(12)
                    
                    Button(action: {
                        if !newTaskTitle.isEmpty {
                            viewModel.addTask(newTaskTitle)
                            newTaskTitle = ""
                            showSheet = false
                        }
                    }) {
                        Text("Добавить")
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .foregroundColor(.white)
                            .background(newTaskTitle.isEmpty ? Color.blue.opacity(0.3) : Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(newTaskTitle.isEmpty)
                }
            }
            .padding(.horizontal, 45)
        }
        .presentationDetents([.height(220)])
        .presentationCornerRadius(30)
        .presentationDragIndicator(.visible)
    }
    
     
    func makeCell(for task: TaskStorable) -> some View {
        HStack {
            Image(systemName: task.isComplete ? "circle.fill" : "circle")
                .foregroundColor(task.isComplete ? .green : .gray)
                .onTapGesture {
                    viewModel.toggleCompletion(for: task)
                }
            
            Text(task.title)
                .strikethrough(task.isComplete, color: .black)
                .foregroundColor(task.isComplete ? .gray : .primary)
                .frame(minWidth: 250, alignment: .leading)
            
            Image(systemName: "trash")
                .foregroundColor(.red)
                .onTapGesture {
                    viewModel.deleteTask(task)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(.horizontal, 16)
        .background(Color(.white))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}

