import SwiftUI
// make sure internet connections in the general settings are allowed!

struct ContentView: View {
    @State private var networkQualityOutput: String = "Click the button to check your network quality."
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Network Quality Test")
                .font(.headline)
            
            ScrollView {
                Text(networkQualityOutput)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
            .border(Color.gray, width: 1)
            
            HStack {
                Button(action: {
                    Task {
                            do {
                                let result = try self.callShell(["-c"])
                                networkQualityOutput = result
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                }) {
                    Text("Run Network Quality Test")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: copyToClipboard) {
                    Text("Copy to Clipboard")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .frame(width: 400, height: 400)
    }
    
    func callShell(_ arguments: [String]) throws -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.executableURL = URL(fileURLWithPath: "/usr/bin/networkQuality")
        task.arguments = arguments // Pass only the needed arguments
        task.standardInput = nil

        try task.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? "No output"

        return output
    }


    
    
    
    
    
    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(networkQualityOutput, forType: .string)
    }
}

#Preview {
    ContentView()
}

