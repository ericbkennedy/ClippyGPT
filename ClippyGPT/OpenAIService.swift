//
//  OpenAIService.swift
//  ClippyGPT
//
//  Created by Eric Kennedy on 6/3/23.
//

import Foundation

class OpenAIService {
    private let endpointURL = "https://api.openai.com/v1/chat/completions"
    
    /// messages is history of all messages in this chat including id and createdAt
    func sendMessage(messages: [Message]) async -> OpenAIChatResponse? {

        guard let url = URL(string: endpointURL) else { return nil }

        // filter out id and createdAt properties before sending to openAI
        let openAIMessages = messages.map({OpenAIChatMessage(role: $0.role, content: $0.content)})
        
        let body = OpenAIChatBody(model: "gpt-3.5-turbo", messages: openAIMessages, stream: false)

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = [
              "Content-Type": "application/json",
              "Authorization": "Bearer \(Constants.openAIApiKey)"
            ]
            request.httpBody = try JSONEncoder().encode(body)
            
            print(String(data: request.httpBody!, encoding: .utf8)!)
                                
            // URLResponse headers not needed so ignored with _ param
            let (responseData, _) = try await URLSession.shared.data(for: request)
            
            print(String(data: responseData, encoding: .utf8)!)
            
            let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: responseData)
            return chatResponse

        } catch {
            print("Error: \(error)")
        }
        return nil
    }
    
    /// send stream message
    func sendStreamMessage(messages: [Message], completion: @escaping (String) -> Void ) async -> Void {
        
        guard let url = URL(string: endpointURL) else { return }
        
        // filter out id and createdAt properties before sending to openAI
        let openAIMessages = messages.map({OpenAIChatMessage(role: $0.role, content: $0.content)})
        
        let body = OpenAIChatBody(model: "gpt-3.5-turbo", messages: openAIMessages, stream: true)
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(Constants.openAIApiKey)"
            ]
            request.httpBody = try JSONEncoder().encode(body)
            
            print(String(data: request.httpBody!, encoding: .utf8)!)
            
            // stream is a URLSession.AsyncBytes. Ignore URLResponse with _ param name
            let (stream, _) = try await URLSession.shared.bytes(for: request)
            
            for try await line in stream.lines {
                guard let message = parse(line) else { continue }
                
                print(message, terminator: "")
                completion(message)
            }
        } catch {
            completion("Error: \(error.localizedDescription)")
            print("Error: \(error)")
        }
    }
 
    /// Parse a line from the stream and extract the message
    /// from https://zachwaugh.com/posts/streaming-messages-chatgpt-swift-asyncsequence
    func parse(_ line: String) -> String? {
        let components = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
        guard components.count == 2, components[0] == "data" else { return nil }

        let message = components[1].trimmingCharacters(in: .whitespacesAndNewlines)

        if message == "[DONE]" { // ChatGPT stream terminator
            return ""
        } else {
            let chunk = try? JSONDecoder().decode(Chunk.self, from: message.data(using: .utf8)!)
           return chunk?.choices.first?.delta.content
        }
    }
    
}

/// Decodes a chunk of the streaming response
struct Chunk: Decodable {
  struct Choice: Decodable {
    struct Delta: Decodable {
      let role: String?
      let content: String?
    }

    let delta: Delta
  }

  let choices: [Choice]
}

struct OpenAIChatBody: Encodable {
    let model: String
    let messages: [OpenAIChatMessage]
    let stream: Bool
}

struct OpenAIChatMessage: Codable {
    let role: SenderRole
    let content: String
}

enum SenderRole: String, Codable {
    case system
    case user
    case assistant
}

struct OpenAIChatResponse: Decodable {
    let choices: [OpenAIChatChoice]
}

struct OpenAIChatChoice: Decodable {
    let message: OpenAIChatMessage
    
}
