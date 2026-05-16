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

// MARK: - Main View (iOS 14 Compatible)
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
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header with Logout
                    HStack {
                        Text("EABVFX")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0, green: 1, blue: 1))
                        Spacer()
                        Button(action: logout) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color(red: 1, green: 0.3, blue: 0))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Activation Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACTIVATION")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 1, green: 0.3, blue: 0))
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
                                .background(Color(red: 0, green: 1, blue: 1))
                                .foregroundColor(.black)
                                .fontWeight(.bold)
                                .cornerRadius(12)
                        }
                        
                        Text(statusText)
                            .font(.headline)
                            .foregroundColor(statusColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text(expiryText)
                            .font(.caption)
                            .foregroundColor(Color(red: 0, green: 1, blue: 1))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding()
                    .background(Color(white: 0.12))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0, green: 1, blue: 1).opacity(0.3), lineWidth: 1))
                    
                    // Video Card (only shown when activated)
                    if isActivated {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("VIDEO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0, green: 1, blue: 1))
                            
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
                            
                            Button(action: processVideo) {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                    }
                                    Text(isProcessing ? "PROCESSING..." : "PROCESS VIDEO")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 1, green: 0.3, blue: 0))
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing || selectedVideoURL == nil)
                            
                            if isProcessing {
                                ProgressView(value: processingProgress, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .accentColor(Color(red: 0, green: 1, blue: 1))
                            }
                        }
                        .padding()
                        .background(Color(white: 0.12))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 1, green: 0.3, blue: 0).opacity(0.3), lineWidth: 1))
                        .transition(.opacity)
                    }
                    
                    // Result Card
                    if showResult {
                        VStack(spacing: 12) {
                            Image(systemName: resultSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(resultSuccess ? .green : .red)
                            Text(resultSuccess ? "SUCCESS" : "FAILED")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(resultSuccess ? Color(red: 0, green: 1, blue: 1) : .red)
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
                    
                    // Social Links Row
                    HStack(spacing: 12) {
                        SocialButton(title: "TikTok", icon: "play.rectangle", color: Color(red: 0, green: 1, blue: 1), url: "https://www.tiktok.com/@eabvfx")
                        SocialButton(title: "Telegram", icon: "paperplane", color: .blue, url: "https://t.me/KurdishAE")
                        SocialButton(title: "🔑 GET KEY", icon: "key", color: Color(red: 1, green: 0.3, blue: 0), url: "https://t.me/EabIdbot")
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
    
    // MARK: - Activation Functions
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
                    UserDefaults.standard.set(response.user_id ?? "", forKey: "userId")
                    self.isActivated = true
                    self.userId = response.user_id
                    self.expiryText = "Expires: \(self.formattedDateTime(expiry))"
                    self.statusText = "ACTIVE"
                    self.statusColor = .green
                } else {
                    self.statusText = "Invalid key"
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
    
    // MARK: - Video Processing
    private func selectVideo() {
        let supportedTypes: [UTType] = [.mpeg4Movie, .quickTimeMovie]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = DocumentPickerDelegate { url in
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

// MARK: - Social Button Component
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

// MARK: - Document Picker Delegate
class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    let onPick: (URL) -> Void
    
    init(onPick: @escaping (URL) -> Void) {
        self.onPick = onPick
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        onPick(url)
    }
}
