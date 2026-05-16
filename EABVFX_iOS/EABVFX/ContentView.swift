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

// MARK: - Sound Manager
class SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?
    
    func playErrorSound() {
        // Create a simple beep sound programmatically
        let systemSoundID: SystemSoundID = 1053 // iPhone default alert sound
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    func playSuccessSound() {
        let systemSoundID: SystemSoundID = 1025 // iPhone success sound
        AudioServicesPlaySystemSound(systemSoundID)
    }
}

// MARK: - Haptic Manager
class HapticManager {
    static let shared = HapticManager()
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

// MARK: - Floating Particles Background (iOS 14 compatible)
struct ParticleBackground: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speed: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color(red: 0, green: 1, blue: 1))
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                        .animation(
                            Animation.linear(duration: particle.speed).repeatForever(autoreverses: false),
                            value: particle.y
                        )
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    private func generateParticles(in size: CGSize) {
        for _ in 0..<30 {
            particles.append(Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.2...0.6),
                speed: Double.random(in: 3...8)
            ))
        }
    }
    
    private func animateParticles(in size: CGSize) {
        for index in particles.indices {
            withAnimation(Animation.linear(duration: particles[index].speed).repeatForever(autoreverses: false)) {
                particles[index].y = size.height + 50
            }
        }
    }
}

// MARK: - API Models
struct VerifyRequest: Codable { let code: String }
struct VerifyResponse: Codable { let success: Bool; let error: String?; let user_id: String? }
struct StatusResponse: Codable { let active: Bool }

// MARK: - Neon Button Style
struct NeonButtonStyle: ButtonStyle {
    var color: Color
    var isWrong: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isWrong ? Color.red : color, lineWidth: 2)
                    .shadow(color: isWrong ? Color.red : color, radius: isWrong ? 8 : 4)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

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
    @State private var showingImagePicker = false
    @State private var shakeTrigger = false
    @State private var wrongKeyTrigger = false
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.07, green: 0.07, blue: 0.13).ignoresSafeArea()
            
            // Floating particles animation
            ParticleBackground()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("EABVFX").font(.system(size: 28, weight: .bold)).foregroundColor(Color(red: 0, green: 1, blue: 1))
                            .shadow(color: Color(red: 0, green: 1, blue: 1), radius: 5)
                        Spacer()
                        Button(action: { 
                            HapticManager.shared.impact()
                            logout() 
                        }) { 
                            Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(Color(red: 1, green: 0.3, blue: 0))
                        }
                    }
                    .padding(.horizontal).padding(.top, 20)
                    
                    // Activation Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACTIVATION").font(.caption).font(.system(size: 12, weight: .bold)).foregroundColor(Color(red: 1, green: 0.3, blue: 0))
                        
                        TextField("Enter your activation key", text: $keyInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white)
                            .colorScheme(.dark)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(wrongKeyTrigger ? Color.red : Color.clear, lineWidth: 2)
                            )
                            .shake($shakeTrigger)
                        
                        Button(action: activate) {
                            Text("ACTIVATE")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(wrongKeyTrigger ? Color.red.opacity(0.3) : Color(red: 0, green: 1, blue: 1))
                                .foregroundColor(.black)
                                .font(.system(size: 16, weight: .bold))
                                .cornerRadius(12)
                                .shadow(color: wrongKeyTrigger ? Color.red : Color(red: 0, green: 1, blue: 1), radius: wrongKeyTrigger ? 10 : 5)
                        }
                        
                        Text(statusText).font(.headline).foregroundColor(statusColor).frame(maxWidth: .infinity, alignment: .center)
                        Text(expiryText).font(.caption).foregroundColor(Color(red: 0, green: 1, blue: 1)).frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding().background(Color(white: 0.12)).cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0, green: 1, blue: 1).opacity(0.3), lineWidth: 1))
                    
                    // Video Card
                    if isActivated {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("VIDEO").font(.caption).font(.system(size: 12, weight: .bold)).foregroundColor(Color(red: 0, green: 1, blue: 1))
                            
                            Button(action: { 
                                HapticManager.shared.impact()
                                showingImagePicker = true 
                            }) {
                                HStack { Image(systemName: "video.badge.plus"); Text(selectedVideoURL?.lastPathComponent ?? "SELECT VIDEO FROM PHOTOS") }
                                .frame(maxWidth: .infinity).padding().background(Color(white: 0.2)).foregroundColor(Color(red: 0, green: 1, blue: 1)).cornerRadius(12)
                            }
                            
                            Button(action: { 
                                HapticManager.shared.impact(style: .heavy)
                                processVideo() 
                            }) {
                                HStack { if isProcessing { ProgressView() }; Text(isProcessing ? "PROCESSING..." : "PROCESS VIDEO") }
                                .frame(maxWidth: .infinity).padding()
                                .background(isProcessing ? Color.gray : Color(red: 1, green: 0.3, blue: 0))
                                .foregroundColor(.white).font(.system(size: 14, weight: .bold)).cornerRadius(12)
                                .shadow(color: Color(red: 1, green: 0.3, blue: 0), radius: 5)
                            }
                            .disabled(isProcessing || selectedVideoURL == nil)
                        }
                        .padding().background(Color(white: 0.12)).cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 1, green: 0.3, blue: 0).opacity(0.3), lineWidth: 1))
                        .transition(.opacity)
                    }
                    
                    // Result Card
                    if showResult {
                        VStack(spacing: 12) {
                            Image(systemName: resultSuccess ? "checkmark.circle.fill" : "xmark.circle.fill").font(.system(size: 50)).foregroundColor(resultSuccess ? .green : .red)
                            Text(resultSuccess ? "SUCCESS" : "FAILED").font(.title2).font(.system(size: 18, weight: .bold)).foregroundColor(resultSuccess ? Color(red: 0, green: 1, blue: 1) : .red)
                            Text(resultMessage).font(.caption).foregroundColor(.gray)
                            
                            if resultSuccess {
                                Button(action: { 
                                    HapticManager.shared.impact()
                                    UIApplication.shared.open(URL(string: "https://www.tiktok.com/upload")!) 
                                }) {
                                    Text("🎬 OPEN TIKTOK STUDIO").frame(maxWidth: .infinity).padding().background(Color(red: 0, green: 1, blue: 1)).foregroundColor(.black).font(.system(size: 14, weight: .bold)).cornerRadius(12)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding().frame(maxWidth: .infinity).background(Color(white: 0.12)).cornerRadius(20)
                    }
                    
                    // Social Buttons
                    HStack(spacing: 12) {
                        Button(action: { HapticManager.shared.impact(); UIApplication.shared.open(URL(string: "https://www.tiktok.com/@eabvfx")!) }) { 
                            Text("TikTok").frame(maxWidth: .infinity).padding(.vertical, 12).background(Color(red: 0, green: 1, blue: 1).opacity(0.2)).foregroundColor(Color(red: 0, green: 1, blue: 1)).cornerRadius(10) 
                        }
                        Button(action: { HapticManager.shared.impact(); UIApplication.shared.open(URL(string: "https://t.me/KurdishAE")!) }) { 
                            Text("Telegram").frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.blue.opacity(0.2)).foregroundColor(.blue).cornerRadius(10) 
                        }
                        Button(action: { HapticManager.shared.impact(); UIApplication.shared.open(URL(string: "https://t.me/EabIdbot")!) }) { 
                            Text("GET KEY").frame(maxWidth: .infinity).padding(.vertical, 12).background(Color(red: 1, green: 0.3, blue: 0).opacity(0.2)).foregroundColor(Color(red: 1, green: 0.3, blue: 0)).cornerRadius(10) 
                        }
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
        guard !keyInput.isEmpty else { 
            triggerWrongKey()
            return 
        }
        
        let url = URL(string: "https://white-brook-5e1f.emadbarzani0011.workers.dev/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["code": keyInput])
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                guard let data = data else { 
                    self.triggerWrongKey()
                    statusText = "Network error"; statusColor = .red
                    return 
                }
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
                        HapticManager.shared.notification(type: .success)
                        SoundManager.shared.playSuccessSound()
                    } else {
                        self.triggerWrongKey()
                        statusText = response.error ?? "Invalid key"; statusColor = .red
                    }
                } catch {
                    self.triggerWrongKey()
                    statusText = "Server error"; statusColor = .red
                }
            }
        }.resume()
    }
    
    private func triggerWrongKey() {
        HapticManager.shared.notification(type: .error)
        SoundManager.shared.playErrorSound()
        wrongKeyTrigger = true
        shakeTrigger = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            wrongKeyTrigger = false
            shakeTrigger = false
        }
    }
    
    private func logout() {
        UserDefaults.standard.removeObject(forKey: "activated")
        UserDefaults.standard.removeObject(forKey: "expiry")
        UserDefaults.standard.removeObject(forKey: "userId")
        isActivated = false; userId = nil; statusText = "Not activated"; statusColor = .gray; expiryText = ""; keyInput = ""
        selectedVideoURL = nil
        showResult = false
        HapticManager.shared.impact()
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
                            if saved {
                                HapticManager.shared.notification(type: .success)
                                SoundManager.shared.playSuccessSound()
                            } else {
                                HapticManager.shared.notification(type: .error)
                            }
                        }
                    }
                } else {
                    throw NSError(domain: "Bypass", code: 1, userInfo: [NSLocalizedDescriptionKey: "elst atom not found"])
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false; self.resultSuccess = false
                    self.resultMessage = error.localizedDescription; self.showResult = true
                    HapticManager.shared.notification(type: .error)
                }
            }
        }
    }
}

// MARK: - PHPickerView (iOS 14+ compatible)
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

// MARK: - Shake Animation Modifier
extension View {
    func shake(_ trigger: Binding<Bool>) -> some View {
        self.modifier(ShakeEffect(trigger: trigger))
    }
}

struct ShakeEffect: ViewModifier {
    @Binding var trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: 0, trigger: trigger) { view, offset in
                view.offset(x: offset)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    CubicKeyframe(-10, duration: 0.05)
                    CubicKeyframe(10, duration: 0.05)
                    CubicKeyframe(-8, duration: 0.05)
                    CubicKeyframe(8, duration: 0.05)
                    CubicKeyframe(-5, duration: 0.05)
                    CubicKeyframe(5, duration: 0.05)
                    CubicKeyframe(0, duration: 0.05)
                }
            }
    }
}
