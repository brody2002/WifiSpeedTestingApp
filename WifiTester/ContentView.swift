import SwiftUI

struct ContentView: View {
    @State private var ping: String = "Ping: 0 ms"
    @State private var downloadSpeed: String = "Download Speed: 0 Mbps"
    @State private var uploadSpeed: String = "Upload Speed: 0 Mbps"
    @State private var isRunning: Bool = false

    var body: some View {
        VStack {
            Text("Real-Time Network Quality")
                .font(.title)
                .padding()
            
            Text(downloadSpeed)
                .font(.body)
                .padding()

            Text(uploadSpeed)
                .font(.body)
                .padding()

            Button(action: {
                print("pressed")
                isRunning = true // Start the network test
                
                Task {
                    do {
                        try startNetworkQualityTest { output in
                            withAnimation {
                                isRunning = false // End the network test
                            }
                            if let parsedDownloadSpeed = parseDownloadSpeed(from: output) {
                                DispatchQueue.main.async {
                                    downloadSpeed = "Download Speed: \(parsedDownloadSpeed) Mbps"
                                }
                            }
                            if let parsedUploadSpeed = parseUploadSpeed(from: output) {
                                DispatchQueue.main.async {
                                    uploadSpeed = "Upload Speed: \(parsedUploadSpeed) Mbps"
                                }
                            }
                        }
                    } catch {
                        print("Error running networkQuality: \(error.localizedDescription)")
                    }
                }
            }) {
                Text(isRunning ? "Testing..." : "Start Network Test")
                    .padding()
                    .background(isRunning ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isRunning ? true : false)
        }
        .padding()
    }

    func startNetworkQualityTest(update: @escaping (String) -> Void) throws {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.executableURL = URL(fileURLWithPath: "/usr/bin/networkQuality")
        task.arguments = ["-cv"]
        task.standardInput = nil

        let handle = pipe.fileHandleForReading

        handle.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                update(output) // Pass the output to the closure
            }
        }

        try task.run()

        // Termination handler
        task.terminationHandler = { _ in
            DispatchQueue.main.async {
                handle.readabilityHandler = nil
            }
        }
    }
    
    func roundToTwoDecimalPoints(value: Double) -> String {
        return String(format: "%.2f", value)
    }




    func parseDownloadSpeed(from output: String) -> String? {
        if let range = output.range(of: "\"dl_throughput\" : (\\d+)", options: .regularExpression) {
            let downloadSpeedString = output[range]
            if let value = downloadSpeedString.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) {
                if let throughput = Double(value) {
                    return String(format: "%.2f", throughput / 1_000_000)
                }
            }
        }
        return nil
    }
    
    func parseUploadSpeed(from output: String) -> String? {
        if let range = output.range(of: "\"ul_throughput\" : (\\d+)", options: .regularExpression) {
            let uploadSpeedString = output[range]
            if let value = uploadSpeedString.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) {
                if let throughput = Double(value) {
                    return String(format: "%.2f", throughput / 1_000_000)
                }
            }
        }
        return nil
    }
}

#Preview {
    ContentView()
}

