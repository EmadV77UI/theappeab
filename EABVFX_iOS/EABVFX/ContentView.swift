import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import AVFoundation
import UIKit

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
        let result = nsData.range(of: Data(pattern), in: NSRange(location: 0, length: nsData.length))
        if result.location != NSNotFound {
            let start = data.index(data.startIndex, offsetBy: result.location)
            let end = data.index(start, offsetBy: result.length)
            return start..<end
        }
        return nil
    }
}

// MARK: - API Models
struct VerifyRequest: Codable { let code: String }
struct VerifyResponse: Codable { let success: Bool; let error: String?; let user_id: String? }
struct StatusResponse: Codable { let active: Bool }

// MARK: - Main View
struct ContentView: View {
    @State private var keyInput = ""
    @State private var isActivated = false
    @State private var userId: String?
    @State private var statusText = "Not activated"
    @State private var expiryText = ""
    @State private var statusColor = Color.gray
    @State private var selectedVideoURL: URL?
    @State private var isProcessing = false
    @State private var resultMessage = ""
    @State private var showResult = false
    @State private var resultSuccess = false
    @State private var timer: Timer?
    @State private var showTikTokStudioButton = false
    @State private var showingImagePicker = false
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.13).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("EABVFX").font(.system(size: 28, weight: .bold)).foregroundColor(Color(red: 0, green: 1, blue: 1))
                        Spacer()
                        Button(action: logout) { Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(Color(red: 1, green: 0.3, blue: 0)) }
                    }
                    .padding(.horizontal).padding(.top, 20)
                    
                    // Activation Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACTIVATION").font(.caption).font(.system(size: 12, weight: .bold)).foregroundColor(Color(red: 1, green: 0.3, blue: 0))
                        TextField("Enter your activation key", text: $keyInput).textFieldStyle(RoundedBorderTextFieldStyle()).foregroundColor(.white).colorScheme(.dark)
                        Button(action: activate) {
                            Text("ACTIVATE").frame(maxWidth: .infinity).padding().background(Color(red: 0, green: 1, blue: 1)).foregroundColor(.black).font(.system(size: 16, weight: .bold)).cornerRadius(12)
                        }
                        Text(statusText).font(.headline).foregroundColor(statusColor).frame(maxWidth: .infinity, alignment: .center)
                        Text(expiryText).font(.caption).foregroundColor(Color(red: 0, green: 1, blue: 1)).frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding().background(Color(white: 0.12)).cornerRadius(20)
                    
                    // Video Card (only when activated)
                    if isActivated {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("VIDEO").font(.caption).font(.system(size: 12, weight: .bold)).foregroundColor(Color(red: 0, green: 1, blue: 1))
                            
                            Button(action: { showingImagePicker = true }) {
                                HStack { Image(systemName: "video.badge.plus"); Text(selectedVideoURL?.lastPathComponent ?? "SELECT VIDEO FROM PHOTOS") }
                                .frame(maxWidth: .infinity).padding().background(Color(white: 0.2)).foregroundColor(.white).cornerRadius(12)
                            }
                            
                            Button(action: processVideo) {
                                HStack { if isProcessing { ProgressView() }; Text(isProcessing ? "PROCESSING..." : "PROCESS VIDEO") }
                                .frame(maxWidth: .infinity).padding().background(isProcessing ? Color.gray : Color(red: 1, green: 0.3, blue: 0))
                                .foregroundColor(.white).font(.system(size: 14, weight: .bold)).cornerRadius(12)
                            }
                            .disabled(isProcessing || selectedVideoURL == nil)
                        }
                        .padding().background(Color(white: 0.12)).cornerRadius(20).transition(.opacity)
                    }
                    
                    // Result Card
                    if showResult {
                        VStack(spacing: 12) {
                            Image(systemName: resultSuccess ? "checkmark.circle.fill" : "xmark.circle.fill").font(.system(size: 50)).foregroundColor(resultSuccess ? .green : .red)
                            Text(resultSuccess ? "SUCCESS" : "FAILED").font(.title2).font(.system(size: 18, weight: .bold)).foregroundColor(resultSuccess ? Color(red: 0, green: 1, blue: 1) : .red)
                            Text(resultMessage).font(.caption).foregroundColor(.gray)
                            
                            if resultSuccess {
                                Button(action: { UIApplication.shared.open(URL(string: "https://www.tiktok.com/upload")!) }) {
                                    Text("🎬 OPEN TIKTOK STUDIO").frame(maxWidth: .infinity).padding().background(Color(red: 0, green: 1, blue: 1)).foregroundColor(.black).font(.system(size: 14, weight: .bold)).cornerRadius(12)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding().frame(maxWidth: .infinity).background(Color(white: 0.12)).cornerRadius(20)
                    }
                    
                    // Social Buttons
                    HStack(spacing: 12) {
                        Button(action: { UIApplication.shared.open(URL(string: "https://www.tiktok.com/@eabvfx")!) }) { Text("TikTok").frame(maxWidth: .infinity).padding(.vertical, 12).background(Color(red: 0, green: 1, blue: 1).opacity(0.2)).foregroundColor(Color(red: 0, green: 1, blue: 1)).cornerRadius(10) }
                        Button(action: { UIApplication.shared.open(URL(string: "https://t.me/KurdishAE")!) }) { Text("Telegram").frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.blue.opacity(0.2)).foregroundColor(.blue).cornerRadius(10) }
                        Button(action: { UIApplication.shared.open(URL(string: "https://t.me/EabIdbot")!) }) { Text("GET KEY").frame(maxWidth: .infinity).padding(.vertical, 12).background(Color(red: 1, green: 0.3, blue: 0).opacity(0.2)).foregroundColor(Color(red: 1, green: 0.3, blue: 0)).cornerRadius(10) }
                    }
                    .padding(.horizontal)
                    
                    Text("© 2026 EABVFX").font(.caption2).foregroundColor(.gray).padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            checkActivation()
            startRemoteLogoutCheck()
        }
        .sheet(isPresented: $showingImagePicker) {
            PHPickerView { url in
                selectedVideoURL = url
            }
        }
    }
    
    private func checkActivation() {
        let defaults = UserDefaults.standard
        isActivated = defaults.bool(forKey: "activated")
        if let expiry = defaults.object(forKey: "expiry") as? Date, expiry > Date() {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd, yyyy HH:mm:ss"
            expiryText = "Expires: \(formatter.string(from: expiry))"
            statusText = "ACTIVE"; statusColor = .green; userId = defaults.string(forKey: "userId")
        } else {
            isActivated = false; statusText = "Not activated"; statusColor = .gray
        }
    }
    
    private func activate() {
        guard !keyInput.isEmpty else { return }
        let url = URL(string: "https://white-brook-5e1f.emadbarzani0011.workers.dev/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["code": keyInput])
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                guard let data = data else { statusText = "Network error"; statusColor = .red; return }
                do {
                    let response = try JSONDecoder().decode(VerifyResponse.self, from: data)
                    if response.success {
                        let expiry = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
                        UserDefaults.standard.set(true, forKey: "activated")
                        UserDefaults.standard.set(expiry, forKey: "expiry")
                        UserDefaults.standard.set(response.user_id ?? "", forKey: "userId")
                        isActivated = true; userId = response.user_id
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MMM dd, yyyy HH:mm:ss"
                        expiryText = "Expires: \(formatter.string(from: expiry))"
                        statusText = "ACTIVE"; statusColor = .green
                    } else {
                        statusText = response.error ?? "Invalid key"; statusColor = .red
                    }
                } catch {
                    statusText = "Server error"; statusColor = .red
                }
            }
        }.resume()
    }
    
    private func logout() {
        UserDefaults.standard.removeObject(forKey: "activated")
        UserDefaults.standard.removeObject(forKey: "expiry")
        UserDefaults.standard.removeObject(forKey: "userId")
        isActivated = false; userId = nil; statusText = "Not activated"; statusColor = .gray; expiryText = ""; keyInput = ""
        selectedVideoURL = nil
        showResult = false
    }
    
    private func startRemoteLogoutCheck() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            guard let uid = userId, isActivated else { return }
            let url = URL(string: "https://white-brook-5e1f.emadbarzani0011.workers.dev/check-status?user_id=\(uid)")!
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data else { return }
                if let status = try? JSONDecoder().decode(StatusResponse.self, from: data), !status.active {
                    DispatchQueue.main.async { self.logout() }
                }
            }.resume()
        }
    }
    
    private func processVideo() {
        guard let inputURL = selectedVideoURL else { return }
        isProcessing = true; showResult = false
        
        Task {
            do {
                let tempOutput = FileManager.default.temporaryDirectory.appendingPathComponent("output_\(Date().timeIntervalSince1970).mp4")
                let success = try await VideoBypass().bypassVideo(inputURL: inputURL, outputURL: tempOutput)
                if success {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempOutput)
                    }) { saved, error in
                        DispatchQueue.main.async {
                            self.isProcessing = false; self.resultSuccess = saved
                            self.resultMessage = saved ? "Video saved to Photos! You can now upload to TikTok." : (error?.localizedDescription ?? "Save failed")
                            self.showResult = true
                        }
                    }
                } else {
                    throw NSError(domain: "Bypass", code: 1, userInfo: [NSLocalizedDescriptionKey: "elst atom not found"])
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false; self.resultSuccess = false
                    self.resultMessage = error.localizedDescription; self.showResult = true
                }
            }
        }
    }
}

// MARK: - PHPickerView (iOS 14+ compatible video picker from Photos)
struct PHPickerView: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first else { return }
            let itemProvider = result.itemProvider
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    guard let url = url else { return }
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("video_\(Date().timeIntervalSince1970).mp4")
                    try? FileManager.default.copyItem(at: url, to: tempURL)
                    DispatchQueue.main.async {
                        self.onPick(tempURL)
                    }
                }
            }
        }
    }
}
