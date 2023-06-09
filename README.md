# ChatGPT iOS client 
This ChatGPT client allows switching between having the responses streamed from ChatGPT or waiting for complete response.

None of the messages are saved locally.

To use, create a file Constants.swift under ClippyGPT

Then add your OpenAPI key there

```
enum Constants {
    static let openAIApiKey = "YOUR-KEY-HERE"
}

```

