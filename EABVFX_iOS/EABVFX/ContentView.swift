import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import AVFoundation
import Combine

// MARK: - Video Bypass Engine
class VideoBypass {
    private let elstSignature: [UInt8] = [0x65, 0x6C, 0x73, 0x74]
    private let payload: UInt32 = 268435457
    
    func bypassVideo(inputURL: URL, outputURL: URL) async throws -> Bool {
        try FileManager.default.copyItem(at: inputURL, to: outputURL)
        let fileData = try Data(contentsOf: outputURL)
        guard let range = findPattern(data: fileData, pattern: elstSignature) else {
            return false
        }
        var patchedData = fileData
        let patchOffset = range.lowerBound + 8
        withUnsafeBytes(of: payload.bigEndian) { bytes in
            patchedData.replaceSubrange(patchOffset..<patchOffset+4, with: bytes)
        }
        try patchedData.write(to: outputURL)
        return true
    }
    
    private func findPattern(data: Data, pattern: [UInt8]) -> Range<Data.Index>? {
        let nsData = data as NSData
        let result = nsData.range(of: Data(pattern))
        return result.location != NSNotFound ? result.range : nil
    }
}

// MARK: - API Models
struct VerifyRequest: Codable {
    let code: String
}
struct VerifyResponse: Codable {
    let success: Bool
    let error: String?
    let user_id: String?
}
struct StatusResponse: Codable {
    let active: Bool
}

// MARK: - Main View
struct ContentView: View {
    @State private var keyInput = ""
    @State private var isActivated = false
    @State private var expiryDate: Date?
    @State private var userId: String?
    @State private var statusText = "Not activated"
    @State private var expiryText = ""
    @State private var statusColor = Color.gray
    
    @State private var selectedVideoURL: URL?
    @State private var isProcessing = false
    @State private var processingProgress = 0.0
    @State private var resultMessage = ""
    @State private var showResult = false
    @State private var resultSuccess = false
    
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.13)
                .ignoresSafeArea()
                .overlay(ParticleView())
            
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text("EABVFX")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan, radius: 10)
                        Spacer()
                        Button(action: logout) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .shadow(color: .orange, radius: 5)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACTIVATION")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .kerning(1)
                        
                        TextField("Enter your activation key", text: $keyInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white)
                            .colorScheme(.dark)
                            .background(Color(white: 0.15))
                            .cornerRadius(8)
                        
                        Button(action: activate) {
                            Text("ACTIVATE")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.cyan)
                                .foregroundColor(.black)
                                .fontWeight(.bold)
                                .cornerRadius(12)
                                .shadow(color: .cyan, radius: 8)
                        }
                        
                        Text(statusText)
                            .font(.headline)
                            .foregroundColor(statusColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text(expiryText)
                            .font(.caption)
                            .foregroundColor(.cyan)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding()
                    .background(Color(white: 0.12))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                    
                    if isActivated {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("VIDEO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.cyan)
                            
                            Button(action: selectVideo) {
                                HStack {
                                    Image(systemName: "video.badge.plus")
                                    Text(selectedVideoURL?.lastPathComponent ?? "SELECT VIDEO")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(white: 0.2))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            if let url = selectedVideoURL {
                                Text(url.lastPathComponent)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Button(action: processVideo) {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }
                                    Text(isProcessing ? "PROCESSING..." : "PROCESS VIDEO")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .cornerRadius(12)
                                .shadow(color: .orange, radius: 8)
                            }
                            .disabled(isProcessing || selectedVideoURL == nil)
                            
                            if isProcessing {
                                ProgressView(value: processingProgress, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                            }
                        }
                        .padding()
                        .background(Color(white: 0.12))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                        .transition(.opacity.combined(with: .scale))
                    }
                    
                    if showResult {
                        VStack(spacing: 12) {
                            Image(systemName: resultSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(resultSuccess ? .green : .red)
                            Text(resultSuccess ? "SUCCESS" : "FAILED")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(resultSuccess ? .cyan : .red)
                            Text(resultMessage)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(white: 0.12))
                        .cornerRadius(20)
                        .transition(.opacity)
                    }
                    
                    HStack(spacing: 12) {
                        SocialButton(title: "TikTok", icon: "play.rectangle", color: .cyan, url: "https://www.tiktok.com/@eabvfx")
                        SocialButton(title: "Telegram", icon: "paperplane", color: .blue, url: "https://t.me/KurdishAE")
                        SocialButton(title: "🔑 GET KEY", icon: "key", color: .orange, url: "https://t.me/EabIdbot")
                    }
                    .padding(.horizontal)
                    
                    Text("© 2026 EABVFX")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            checkActivation()
            startRemoteLogoutCheck()
        }
    }
    
    private func checkActivation() {
        let defaults = UserDefaults.standard
        isActivated = defaults.bool(forKey: "activated")
        if let expiry = defaults.object(forKey: "expiry") as? Date {
            if expiry > Date() {
                expiryText = "Expires: \(formattedDateTime(expiry))"
                statusText = "ACTIVE"
                statusColor = .green
                userId = defaults.string(forKey: "userId")
            } else {
                logout()
            }
        } else {
            isActivated = false
            statusText = "Not activated"
            statusColor = .gray
        }
    }
    
    private func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func activate() {
        guard !keyInput.isEmpty else { return }
        
        let url = URL(string: "https://white-brook-5e1f.emadbarzani0011.workers.dev/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(VerifyRequest(code: keyInput))
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let data = data,
                   let response = try? JSONDecoder().decode(VerifyResponse.self, from: data),
                   response.success == true {
                    let expiry = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
                    UserDefaults.standard.set(true, forKey: "activated")
                    UserDefaults.standard.set(expiry, forKey: "expiry")
                    UserDefaults.standard.set(response.user_id, forKey: "userId")
                    self.isActivated = true
                    self.userId = response.user_id
                    self.expiryText = "Expires: \(self.formattedDateTime(expiry))"
                    self.statusText = "ACTIVE"
                    self.statusColor = .green
                } else {
                    self.statusText = response?.error ?? "Invalid key"
                    self.statusColor = .red
                }
            }
        }.resume()
    }
    
    private func logout() {
        UserDefaults.standard.removeObject(forKey: "activated")
        UserDefaults.standard.removeObject(forKey: "expiry")
        UserDefaults.standard.removeObject(forKey: "userId")
        isActivated = false
        userId = nil
        statusText = "Not activated"
        statusColor = .gray
        expiryText = ""
    }
    
    private func startRemoteLogoutCheck() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            guard let uid = userId, isActivated else { return }
            let url = URL(string: "https://white-brook-5e1f.emadbarzani0011.workers.dev/check-status?user_id=\(uid)")!
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data,
                   let status = try? JSONDecoder().decode(StatusResponse.self, from: data),
                   !status.active {
                    DispatchQueue.main.async {
                        self.logout()
                    }
                }
            }.resume()
        }
    }
    
    private func selectVideo() {
        let picker = DocumentPicker()
        picker.didPickDocument = { url in
            self.selectedVideoURL = url
        }
        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
    }
    
    private func processVideo() {
        guard let inputURL = selectedVideoURL else { return }
        isProcessing = true
        processingProgress = 0.0
        showResult = false
        
        Task {
            do {
                processingProgress = 0.3
                let tempOutput = FileManager.default.temporaryDirectory.appendingPathComponent("output_\(Date().timeIntervalSince1970).mp4")
                let success = try await VideoBypass().bypassVideo(inputURL: inputURL, outputURL: tempOutput)
                processingProgress = 0.8
                
                if success {
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempOutput)
                    } completionHandler: { saved, error in
                        DispatchQueue.main.async {
                            self.isProcessing = false
                            self.resultSuccess = saved
                            self.resultMessage = saved ? "Video saved to Photos" : "Failed to save: \(error?.localizedDescription ?? "")"
                            self.showResult = true
                        }
                    }
                } else {
                    throw NSError(domain: "Bypass", code: 1, userInfo: [NSLocalizedDescriptionKey: "elst atom not found"])
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.resultSuccess = false
                    self.resultMessage = error.localizedDescription
                    self.showResult = true
                }
            }
        }
    }
}

struct SocialButton: View {
    let title: String
    let icon: String
    let color: Color
    let url: String
    
    var body: some View {
        Button(action: {
            UIApplication.shared.open(URL(string: url)!)
        }) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 1))
        }
    }
}

struct ParticleView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var speedX: Double
        var speedY: Double
        var color: Color
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    var newX = particle.x + particle.speedX
                    var newY = particle.y + particle.speedY
                    if newX < 0 { newX = size.width }
                    if newX > size.width { newX = 0 }
                    if newY < 0 { newY = size.height }
                    if newY > size.height { newY = 0 }
                    
                    let rect = CGRect(x: newX, y: newY, width: particle.size, height: particle.size)
                    context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                }
            }
        }
        .onAppear {
            for _ in 0..<50 {
                particles.append(Particle(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                    size: CGFloat.random(in: 2...5),
                    speedX: Double.random(in: -0.5...0.5),
                    speedY: Double.random(in: -0.5...0.5),
                    color: Bool.random() ? .cyan : .orange
                ))
            }
        }
    }
}

class DocumentPicker: NSObject, UIDocumentPickerDelegate {
    var didPickDocument: ((URL) -> Void)?
    private var picker: UIDocumentPickerViewController?
    
    func present() {
        let supportedTypes: [UTType] = [.mpeg4Movie, .quickTimeMovie]
        picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker?.delegate = self
        picker?.allowsMultipleSelection = false
        UIApplication.shared.windows.first?.rootViewController?.present(picker!, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        didPickDocument?(url)
    }
}