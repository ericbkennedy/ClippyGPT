//
//  ChatView.swift
//  ClippyGPT
//
//  Created by Eric Kennedy on 6/3/23.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel = ViewModel()

    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView(.vertical) { // User must scroll off the top to enable programmatic scrolling
                    VStack {            // Simplifies scrollTo using id "VStackInScrollView"
                        ForEach(viewModel.messages.filter({$0.role != .system}),
                                id: \.id)
                        { message in
                            messageView(message: message)
                        }
                    }.id("VStackInScrollView")
                }.onChange(of: viewModel.totalResponseCount) { _ in
                    withAnimation {
                        scrollView.scrollTo("VStackInScrollView", anchor: .bottom)
                    }
                }
            }
            HStack {
                TextField("Enter a message",
                          text: $viewModel.currentInput,
                          axis: .vertical )
                    .lineLimit(2...10)
                    .onSubmit {
                        viewModel.sendMessage() // enables submit on return key press
                    }
                    .padding()
                    .textFieldStyle(.roundedBorder)
                Button {
                    viewModel.sendMessage()
                } label: {
                    Text("Send")
                }
            }
            Toggle("Streaming", isOn: $viewModel.streamResponse)
        }
        .padding()
    }
    
    func messageView(message: Message) -> some View {
        HStack {
            if message.role == .user { Spacer() }
            Text(message.content)
                .padding()
                .background(message.role == .user ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .cornerRadius(15.0)
            if message.role == .assistant { Spacer() }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
