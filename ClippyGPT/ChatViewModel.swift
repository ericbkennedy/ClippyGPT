//
//  ChatViewModel.swift
//  ClippyGPT
//
//  Created by Eric Kennedy on 6/3/23.
//

import Foundation

extension ChatView {
    class ViewModel: ObservableObject {
        @Published var messages: [Message] = []
        @Published var totalResponseCount: Int = 0 // Updates with streamed response for improved onChange scrolling
        @Published var currentInput: String = ""
        @Published var streamResponse = true
        
        private let openAIService = OpenAIService()
        
        func sendMessage() {
            let userMessage = Message(id: UUID(), role: .user, content: currentInput, createAt: Date())
            messages.append(userMessage)
            currentInput = "" // reset current input before user's next question
            
            // Start with ". . ." for streaming response
            let agentMessage = Message(id: UUID(), role: .assistant, content: ". . .", createAt: Date())
            messages.append(agentMessage)
            let pendingMessageIndex = messages.count - 1
            
            if (streamResponse) {
                self.requestStreamingResponse(pendingMessageIndex)
            } else {
                self.requestCompleteResponse(pendingMessageIndex)
            }
        }
        
        private func requestCompleteResponse(_ pendingMessageIndex: Int) {
            Task {
                let response = await openAIService.sendMessage(messages: messages)
                
                DispatchQueue.main.async {
                    var responseMessage = "Error: No response received" // will be overridden by successful response
                    if let receivedOpenAIMessage = response?.choices.first?.message {
                        responseMessage = receivedOpenAIMessage.content
                    }
                    self.updatePendingMessageWithString(responseMessage, pendingMessageIndex: pendingMessageIndex)
                }
            }
        }
        
        private func requestStreamingResponse(_ pendingMessageIndex: Int) {

            // Note: add new message before starting background Task
            
            Task {
                await openAIService.sendStreamMessage(messages: messages, completion: { newChunk in
                    DispatchQueue.main.async {
                        self.updatePendingMessageWithString(newChunk, pendingMessageIndex: pendingMessageIndex)
                    }
                });
            }
        }
        
        private func updatePendingMessageWithString(_ newText: String, pendingMessageIndex: Int) {
            if (self.messages[pendingMessageIndex].content == ". . .") {
                self.messages[pendingMessageIndex].content = ""
            }
            self.messages[pendingMessageIndex].content += newText
            self.totalResponseCount += 1
        }
    }
}

struct Message: Decodable {
    let id: UUID
    let role: SenderRole
    var content: String
    let createAt: Date
}
