import SwiftUI
import WebKit

@main
struct EABVFXBoostApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct WebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1.0)
        
        let htmlString = getHTMLString()
        webView.loadHTMLString(htmlString, baseURL: nil)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func getHTMLString() -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, viewport-fit=cover">
            <title>EABVFX • RED PHANTOM CORE</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                    -webkit-tap-highlight-color: transparent;
                }
        
                body {
                    background: radial-gradient(circle at 30% 20%, #0a0000 0%, #010000 100%);
                    font-family: 'Segoe UI', 'Inter', 'Poppins', monospace;
                    min-height: 100vh;
                    overflow-x: hidden;
                    color: #e0e0e0;
                    transition: background 0.8s ease;
                    cursor: crosshair;
                }
        
                body::before {
                    content: "";
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background-image: 
                        linear-gradient(rgba(255, 40, 20, 0.15) 1px, transparent 1px),
                        linear-gradient(90deg, rgba(255, 40, 20, 0.15) 1px, transparent 1px);
                    background-size: 45px 45px;
                    pointer-events: none;
                    animation: driftGrid 14s linear infinite;
                    z-index: 0;
                }
        
                @keyframes driftGrid {
                    0% { transform: translateY(0px) translateX(0px); }
                    100% { transform: translateY(45px) translateX(45px); }
                }
        
                body::after {
                    content: "";
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background: repeating-linear-gradient(0deg, 
                        rgba(255, 30, 0, 0.1) 0px,
                        rgba(255, 30, 0, 0.1) 2px,
                        transparent 2px,
                        transparent 8px);
                    pointer-events: none;
                    z-index: 0;
                }
        
                #particle-canvas {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    z-index: 1;
                    pointer-events: none;
                }
        
                .container {
                    position: relative;
                    z-index: 10;
                    max-width: 550px;
                    margin: 0 auto;
                    padding: 20px;
                    min-height: 100vh;
                    padding-bottom: 80px;
                }
        
                .timer-bar {
                    background: rgba(8, 0, 0, 0.88);
                    backdrop-filter: blur(12px);
                    border-radius: 28px;
                    padding: 12px 18px;
                    margin-bottom: 20px;
                    border: 1px solid #ff5555;
                    box-shadow: 0 0 12px rgba(255, 0, 0, 0.3);
                }
        
                .timer-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    margin-bottom: 8px;
                }
        
                .timer-label {
                    font-size: 11px;
                    color: #ffaa88;
                    letter-spacing: 1px;
                }
        
                .timer-value {
                    font-family: monospace;
                    font-size: 18px;
                    font-weight: bold;
                    color: #ff6666;
                    text-shadow: 0 0 5px #ff2200;
                }
        
                .timer-progress {
                    height: 4px;
                    background: rgba(255, 255, 255, 0.1);
                    border-radius: 4px;
                    overflow: hidden;
                }
        
                .timer-progress-bar {
                    height: 100%;
                    background: linear-gradient(90deg, #ff4444, #ffaa66);
                    width: 100%;
                    transition: width 1s linear;
                }
        
                .card {
                    background: rgba(8, 0, 0, 0.88);
                    backdrop-filter: blur(20px);
                    border-radius: 32px;
                    border: 1px solid #ff5555;
                    box-shadow: 0 20px 40px rgba(0,0,0,0.7), 0 0 30px rgba(255,0,0,0.5);
                    padding: 24px;
                    margin-bottom: 20px;
                    text-align: center;
                }
        
                .logo-ring svg {
                    width: 48px;
                    fill: #ff5555;
                    margin-bottom: 10px;
                }
        
                h1 {
                    font-family: 'Segoe UI', 'Rajdhani', sans-serif;
                    font-size: 26px;
                    letter-spacing: 2px;
                    background: linear-gradient(135deg, #ff5555, #ffaa77);
                    -webkit-background-clip: text;
                    background-clip: text;
                    color: transparent;
                }
        
                .highlight { color: #ff8866; }
        
                .subtitle {
                    color: #ffaa88;
                    font-size: 11px;
                    margin-top: 5px;
                    border-left: 2px solid #ff6666;
                    padding-left: 10px;
                    display: inline-block;
                }
        
                .file-picker-area {
                    background: rgba(30, 5, 5, 0.8);
                    border: 2px dashed #ff6666;
                    border-radius: 28px;
                    padding: 32px 20px;
                    text-align: center;
                    cursor: pointer;
                    transition: all 0.2s;
                    margin-bottom: 20px;
                }
        
                .file-picker-area:hover {
                    background: #2a0808;
                    border-color: #ffaa88;
                    box-shadow: 0 0 16px #ff4444;
                }
        
                .file-picker-area svg {
                    width: 48px;
                    fill: #ff6666;
                    margin-bottom: 12px;
                }
        
                .file-info {
                    background: rgba(0,0,0,0.6);
                    border-radius: 20px;
                    padding: 14px;
                    margin: 15px 0;
                    font-size: 13px;
                    border-left: 3px solid #ff4444;
                }
        
                .file-info div {
                    display: flex;
                    justify-content: space-between;
                    margin-bottom: 8px;
                }
        
                .file-info span:first-child { color: #ffaa88; }
                .file-info span:last-child { color: #ff7777; font-weight: bold; }
        
                .cyber-btn {
                    width: 100%;
                    padding: 14px;
                    background: linear-gradient(95deg, #cc2200, #ff6644);
                    border: none;
                    border-radius: 60px;
                    font-weight: 800;
                    font-size: 16px;
                    letter-spacing: 1px;
                    color: white;
                    text-shadow: 0 1px 2px black;
                    cursor: pointer;
                    transition: 0.05s linear;
                    box-shadow: 0 5px 0 #661100;
                    transform: translateY(-2px);
                    margin-bottom: 12px;
                }
        
                .cyber-btn:active {
                    transform: translateY(3px);
                    box-shadow: 0 1px 0 #661100;
                }
        
                .cyber-btn:disabled {
                    opacity: 0.6;
                    transform: translateY(0);
                    cursor: not-allowed;
                }
        
                .social-actions {
                    display: flex;
                    gap: 12px;
                    margin: 20px 0 10px;
                }
        
                .social-btn {
                    flex: 1;
                    padding: 10px;
                    border-radius: 40px;
                    text-align: center;
                    text-decoration: none;
                    font-weight: 700;
                    font-size: 13px;
                    transition: 0.2s;
                }
        
                .btn-tiktok, .btn-telegram {
                    background: #1f0606;
                    border: 1px solid #ff5555;
                    color: #ffaa77;
                }
        
                .social-btn:hover {
                    background: #3a0a0a;
                    color: #ffccaa;
                    box-shadow: 0 0 10px red;
                }
        
                .footer {
                    text-align: center;
                    margin-top: 20px;
                    font-size: 10px;
                    color: #aa6655;
                }
        
                .login-screen {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background: #0a0000e6;
                    backdrop-filter: blur(12px);
                    z-index: 1000;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
        
                .login-card {
                    background: #0f0202;
                    border: 2px solid #ff4444;
                    border-radius: 48px;
                    padding: 2.5rem;
                    width: 85%;
                    max-width: 380px;
                    text-align: center;
                    box-shadow: 0 0 70px rgba(255, 0, 0, 0.5);
                    animation: flickerRed 2s infinite;
                }
        
                @keyframes flickerRed {
                    0% { border-color: #ff4444; box-shadow: 0 0 20px red; }
                    50% { border-color: #ff8888; box-shadow: 0 0 50px #ff5500; }
                    100% { border-color: #ff4444; box-shadow: 0 0 20px red; }
                }
        
                .login-card h2 {
                    color: #ff6666;
                    margin: 15px 0;
                    font-size: 1.8rem;
                    text-shadow: 0 0 8px red;
                }
        
                .login-card input {
                    width: 100%;
                    padding: 14px;
                    margin: 20px 0;
                    background: #1a0303;
                    border: 1px solid #ff4444;
                    color: #ffaaaa;
                    font-size: 1rem;
                    text-align: center;
                    letter-spacing: 1px;
                    border-radius: 60px;
                }
        
                .error-msg {
                    color: #ff8888;
                    font-size: 12px;
                    margin-top: 10px;
                    min-height: 30px;
                }
        
                .success-animation {
                    position: fixed;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    background: #0a0000ee;
                    backdrop-filter: blur(16px);
                    border-radius: 32px;
                    padding: 30px;
                    text-align: center;
                    z-index: 1100;
                    animation: fadeInOut 2s ease;
                    border: 1px solid #2ecc71;
                }
        
                @keyframes fadeInOut {
                    0% { opacity: 0; transform: translate(-50%, -50%) scale(0.8); }
                    20% { opacity: 1; transform: translate(-50%, -50%) scale(1); }
                    80% { opacity: 1; transform: translate(-50%, -50%) scale(1); }
                    100% { opacity: 0; transform: translate(-50%, -50%) scale(0.8); }
                }
        
                .spinner {
                    display: inline-block;
                    width: 18px;
                    height: 18px;
                    border: 2px solid rgba(255,255,255,0.3);
                    border-radius: 50%;
                    border-top-color: white;
                    animation: spin 0.6s linear infinite;
                    margin-right: 8px;
                }
        
                @keyframes spin { to { transform: rotate(360deg); } }
        
                .hidden { display: none !important; }
        
                .light-mode { background: #f0e6e0; }
                .light-mode .card, .light-mode .timer-bar, .light-mode .file-picker-area {
                    background: rgba(255,245,240,0.95);
                    color: #2a1a1a;
                }
                .light-mode .file-info { background: #f0e0d8; }
                .light-mode .cyber-btn { background: linear-gradient(95deg, #aa3300, #cc5533); }
            </style>
        </head>
        <body>
            <canvas id="particle-canvas"></canvas>
        
            <div id="loginScreen" class="login-screen">
                <div class="login-card">
                    <div class="logo-ring"><svg viewBox="0 0 24 24"><path d="M12 2L2 7l10 5 10-5-10-5zm0 9l2.5-1.25L12 8.5l-2.5 1.25L12 11zm0 2.5l-5-2.5-5 2.5L12 22l10-8.5-5-2.5-5 2.5z"/></svg></div>
                    <h2>EABVFX <span style="color:#ff7777;">BOOSTER</span></h2>
                    <input type="text" id="licenseKey" placeholder="License Key" autocomplete="off">
                    <button id="verifyBtn" class="cyber-btn" style="background: #aa2222; box-shadow: 0 5px 0 #551100;">VERIFY</button>
                    <div id="loginError" class="error-msg"></div>
                    <div style="margin-top: 15px; font-size: 11px;"><a href="https://t.me/EabIdbot" target="_blank" style="color:#ffaa77;">🔑 Get License</a></div>
                </div>
            </div>
        
            <div id="mainApp" class="container hidden">
                <div class="timer-bar">
                    <div class="timer-header">
                        <span class="timer-label">⏰ SUBSCRIPTION REMAINING</span>
                        <span class="timer-value" id="timerDisplay">---</span>
                    </div>
                    <div class="timer-progress"><div class="timer-progress-bar" id="timerProgress"></div></div>
                </div>
        
                <div class="card">
                    <div class="logo-ring"><svg viewBox="0 0 24 24"><path d="M12 2L2 7l10 5 10-5-10-5zm0 9l2.5-1.25L12 8.5l-2.5 1.25L12 11zm0 2.5l-5-2.5-5 2.5L12 22l10-8.5-5-2.5-5 2.5z"/></svg></div>
                    <h1>EABVFX <span class="highlight">BOOSTER</span></h1>
                    <div class="subtitle">TikTok Quality Bypass • Audio Preserved</div>
                </div>
        
                <div class="file-picker-area" id="filePicker">
                    <svg viewBox="0 0 24 24"><path d="M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM14 13v4h-4v-4H7l5-5 5 5h-3z"/></svg>
                    <div style="font-weight: 600;">Select Video</div>
                    <div style="font-size: 11px; opacity:0.7;">MP4 or MOV</div>
                </div>
        
                <div id="fileInfo" class="file-info" style="display: none;">
                    <div><span>📹 Filename:</span><span id="fileName">---</span></div>
                    <div><span>📏 Size:</span><span id="fileSize">---</span></div>
                    <div><span>🎬 Resolution:</span><span id="fileResolution">---</span></div>
                </div>
        
                <button id="bypassBtn" class="cyber-btn" disabled>PROCESS VIDEO (PRESERVE AUDIO)</button>
                <button id="logoutBtn" class="cyber-btn" style="background: #aa2222; box-shadow: 0 5px 0 #551100;">LOGOUT</button>
        
                <div class="social-actions">
                    <a href="https://www.tiktok.com/@eabvfx" class="social-btn btn-tiktok">📱 TikTok</a>
                    <a href="https://t.me/KurdishAE" class="social-btn btn-telegram">💬 Telegram</a>
                </div>
                <div class="footer">Made by EABVFX | AUDIO PRESERVED</div>
            </div>
        
            <input type="file" id="videoInput" accept="video/mp4,video/quicktime" style="display: none;">
        
            <script>
                const WORKER_BASE = 'https://white-brook-5e1f.emadbarzani0011.workers.dev';
                const VERIFY_URL = WORKER_BASE + '/verify';
                const CHECK_URL = WORKER_BASE + '/check-subscription';
        
                let inactivityTimer = null;
                let subscriptionInterval = null;
                let currentExpiry = null;
        
                function resetInactivityTimer() {
                    if (inactivityTimer) clearTimeout(inactivityTimer);
                    inactivityTimer = setTimeout(() => { logout(); }, 5 * 60 * 1000);
                }
        
                function logout() {
                    localStorage.removeItem('eabvfx_authenticated');
                    localStorage.removeItem('eabvfx_expiry');
                    localStorage.removeItem('eabvfx_user_id');
                    if (subscriptionInterval) clearInterval(subscriptionInterval);
                    document.getElementById('loginScreen').style.display = 'flex';
                    document.getElementById('mainApp').classList.add('hidden');
                    document.getElementById('licenseKey').value = '';
                    document.getElementById('loginError').innerHTML = '⏰ Session expired. Login again.';
                }
        
                function formatTimeRemaining(ms) {
                    if (ms <= 0) return 'EXPIRED';
                    const days = Math.floor(ms / (1000*60*60*24));
                    const hours = Math.floor((ms % (86400000)) / 3600000);
                    const minutes = Math.floor((ms % 3600000) / 60000);
                    if (days > 0) return days + "d " + hours + "h " + minutes + "m";
                    if (hours > 0) return hours + "h " + minutes + "m";
                    return minutes + "m";
                }
        
                function updateTimerDisplay() {
                    if (!currentExpiry) return;
                    const remaining = currentExpiry - Date.now();
                    const timerDisplay = document.getElementById('timerDisplay');
                    const timerProgress = document.getElementById('timerProgress');
                    if (remaining <= 0) {
                        timerDisplay.innerHTML = 'EXPIRED';
                        timerProgress.style.width = '0%';
                        logout();
                        return;
                    }
                    timerDisplay.innerHTML = formatTimeRemaining(remaining);
                    const totalDuration = 30 * 24 * 60 * 60 * 1000;
                    let percent = Math.max(0, (remaining / totalDuration) * 100);
                    timerProgress.style.width = percent + '%';
                }
        
                function startSubscriptionTimer(expiryDate) {
                    if (subscriptionInterval) clearInterval(subscriptionInterval);
                    currentExpiry = expiryDate;
                    updateTimerDisplay();
                    subscriptionInterval = setInterval(updateTimerDisplay, 1000);
                }
        
                async function verifyLicense(licenseKey) {
                    try {
                        const response = await fetch(VERIFY_URL, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ code: licenseKey })
                        });
                        const data = await response.json();
                        if (data.success) {
                            const userId = data.user_id;
                            const checkResp = await fetch(CHECK_URL + "?user=" + userId);
                            const checkData = await checkResp.json();
                            if (checkData.active && checkData.expires) {
                                const expiry = new Date(checkData.expires).getTime();
                                localStorage.setItem('eabvfx_authenticated', 'true');
                                localStorage.setItem('eabvfx_expiry', expiry);
                                localStorage.setItem('eabvfx_user_id', userId);
                                return { success: true, expiry: expiry };
                            } else return { success: false, error: 'Subscription expired.' };
                        } else return { success: false, error: data.error || 'Invalid code.' };
                    } catch(e) { return { success: false, error: 'Network error.' }; }
                }
        
                async function checkExistingSession() {
                    const authenticated = localStorage.getItem('eabvfx_authenticated');
                    const expiry = parseInt(localStorage.getItem('eabvfx_expiry'));
                    if (authenticated === 'true' && expiry && expiry > Date.now()) return { valid: true, expiry: expiry };
                    return { valid: false };
                }
        
                // ============ NAL REMOVAL - PRESERVES AUDIO ============
                const REMOVE_NAL_TYPES = new Set([6, 9]);
        
                async function bypassWithNALRemoval(file) {
                    return new Promise((resolve, reject) => {
                        const reader = new FileReader();
                        reader.onload = function(e) {
                            let originalData = new Uint8Array(e.target.result);
                            let output = [];
                            let i = 0;
                            let removedCount = 0;
                            let modified = false;
                            
                            while (i < originalData.length) {
                                let startCodeLen = 0;
                                let isStartCode = false;
                                
                                if (i + 3 < originalData.length && 
                                    originalData[i] === 0x00 && originalData[i+1] === 0x00 && 
                                    originalData[i+2] === 0x00 && originalData[i+3] === 0x01) {
                                    isStartCode = true;
                                    startCodeLen = 4;
                                }
                                else if (i + 2 < originalData.length && 
                                         originalData[i] === 0x00 && originalData[i+1] === 0x00 && 
                                         originalData[i+2] === 0x01) {
                                    isStartCode = true;
                                    startCodeLen = 3;
                                }
                                
                                if (isStartCode && i + startCodeLen < originalData.length) {
                                    let nalType = originalData[i + startCodeLen] & 0x1F;
                                    
                                    if (REMOVE_NAL_TYPES.has(nalType)) {
                                        let nalEnd = i + startCodeLen;
                                        while (nalEnd < originalData.length) {
                                            let foundNext = false;
                                            if (nalEnd + 3 < originalData.length &&
                                                originalData[nalEnd] === 0x00 && originalData[nalEnd+1] === 0x00 &&
                                                originalData[nalEnd+2] === 0x00 && originalData[nalEnd+3] === 0x01) {
                                                foundNext = true;
                                            }
                                            else if (nalEnd + 2 < originalData.length &&
                                                     originalData[nalEnd] === 0x00 && originalData[nalEnd+1] === 0x00 &&
                                                     originalData[nalEnd+2] === 0x01) {
                                                foundNext = true;
                                            }
                                            if (foundNext) break;
                                            nalEnd++;
                                        }
                                        i = nalEnd;
                                        removedCount++;
                                        modified = true;
                                        continue;
                                    }
                                }
                                
                                output.push(originalData[i]);
                                i++;
                            }
                            
                            if (!modified) {
                                let patchedBlob = new Blob([originalData], { type: file.type });
                                let originalName = file.name;
                                let baseName = originalName.substring(0, originalName.lastIndexOf('.')) || originalName;
                                let outName = baseName + '_EABVFX.mp4';
                                resolve({ success: true, blob: patchedBlob, filename: outName, removed: 0 });
                                return;
                            }
                            
                            let patchedBlob = new Blob([new Uint8Array(output)], { type: file.type });
                            let originalName = file.name;
                            let baseName = originalName.substring(0, originalName.lastIndexOf('.')) || originalName;
                            let outName = baseName + '_EABVFX_NAL.mp4';
                            resolve({ success: true, blob: patchedBlob, filename: outName, removed: removedCount });
                        };
                        reader.onerror = function() { reject('File read error'); };
                        reader.readAsArrayBuffer(file);
                    });
                }
        
                // UI Elements
                const filePicker = document.getElementById('filePicker');
                const videoInput = document.getElementById('videoInput');
                const bypassBtn = document.getElementById('bypassBtn');
                let selectedFile = null;
        
                filePicker.addEventListener('click', () => videoInput.click());
                videoInput.addEventListener('change', (e) => {
                    const file = e.target.files[0];
                    if (!file) return;
                    selectedFile = file;
                    document.getElementById('fileName').textContent = file.name.length > 35 ? file.name.slice(0,32)+'...' : file.name;
                    document.getElementById('fileSize').textContent = (file.size / (1024*1024)).toFixed(2) + ' MB';
                    
                    const video = document.createElement('video');
                    video.preload = 'metadata';
                    video.onloadedmetadata = function() {
                        URL.revokeObjectURL(video.src);
                        document.getElementById('fileResolution').textContent = video.videoWidth + 'x' + video.videoHeight;
                        document.getElementById('fileInfo').style.display = 'block';
                        bypassBtn.disabled = false;
                    };
                    video.src = URL.createObjectURL(file);
                    
                    resetInactivityTimer();
                });
        
                bypassBtn.addEventListener('click', async () => {
                    if (!selectedFile) return;
                    resetInactivityTimer();
                    bypassBtn.disabled = true;
                    const originalText = bypassBtn.innerHTML;
                    bypassBtn.innerHTML = '<span class="spinner"></span> PROCESSING (KEEPING AUDIO)...';
                    try {
                        const result = await bypassWithNALRemoval(selectedFile);
                        if (result.success) {
                            const successDiv = document.createElement('div');
                            successDiv.className = 'success-animation';
                            let message = '<svg viewBox="0 0 24 24" style="width:50px; fill:#2ecc71;"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg><div style="font-weight:800;">SUCCESS!</div>';
                            if (result.removed > 0) {
                                message += '<div style="font-size:11px">Removed ' + result.removed + ' NAL units<br>Audio preserved!</div>';
                            } else {
                                message += '<div style="font-size:11px">Video ready<br>Audio intact</div>';
                            }
                            successDiv.innerHTML = message;
                            document.body.appendChild(successDiv);
                            
                            const url = URL.createObjectURL(result.blob);
                            const a = document.createElement('a');
                            a.href = url;
                            a.download = result.filename;
                            document.body.appendChild(a);
                            a.click();
                            document.body.removeChild(a);
                            URL.revokeObjectURL(url);
                            setTimeout(() => { successDiv.remove(); }, 2500);
                        }
                    } catch (err) {
                        alert('Error: ' + err.message);
                    } finally {
                        bypassBtn.innerHTML = originalText;
                        bypassBtn.disabled = false;
                    }
                });
        
                const verifyBtnUI = document.getElementById('verifyBtn');
                const loginScreen = document.getElementById('loginScreen');
                const mainApp = document.getElementById('mainApp');
                const logoutBtn = document.getElementById('logoutBtn');
        
                verifyBtnUI.addEventListener('click', async () => {
                    const license = document.getElementById('licenseKey').value.trim();
                    const errorDiv = document.getElementById('loginError');
                    if (!license) { errorDiv.innerHTML = '❌ Enter license key'; return; }
                    errorDiv.innerHTML = 'Verifying...';
                    const result = await verifyLicense(license);
                    if (result.success) {
                        errorDiv.innerHTML = '';
                        loginScreen.style.display = 'none';
                        mainApp.classList.remove('hidden');
                        startSubscriptionTimer(result.expiry);
                        resetInactivityTimer();
                    } else {
                        errorDiv.innerHTML = '❌ ' + (result.error || 'Invalid license');
                    }
                });
        
                logoutBtn.addEventListener('click', () => logout());
        
                (async () => {
                    const session = await checkExistingSession();
                    if (session.valid) {
                        loginScreen.style.display = 'none';
                        mainApp.classList.remove('hidden');
                        startSubscriptionTimer(session.expiry);
                        resetInactivityTimer();
                    }
                })();
        
                // Particles animation
                const canvas = document.getElementById('particle-canvas');
                const ctx = canvas.getContext('2d');
                let width = window.innerWidth, height = window.innerHeight;
                let particles = [];
                function resizeCanvas() { canvas.width = width; canvas.height = height; }
                window.addEventListener('resize', () => { width = window.innerWidth; height = window.innerHeight; resizeCanvas(); });
                resizeCanvas();
                for (let i=0; i<120; i++) {
                    particles.push({
                        x: Math.random() * width, y: Math.random() * height,
                        size: 2 + Math.random() * 5,
                        vx: (Math.random() - 0.5) * 0.7, vy: 0.3 + Math.random() * 1.2,
                        alpha: 0.4 + Math.random() * 0.5
                    });
                }
                function animateParticles() {
                    ctx.clearRect(0, 0, width, height);
                    for (let p of particles) {
                        p.x += p.vx; p.y += p.vy;
                        if (p.x < -20) p.x = width+20;
                        if (p.x > width+20) p.x = -20;
                        if (p.y > height+30) { p.y = -20; p.x = Math.random() * width; }
                        if (p.y < -20) p.y = height+30;
                        ctx.beginPath();
                        ctx.arc(p.x, p.y, p.size, 0, Math.PI*2);
                        ctx.fillStyle = "rgba(255, 70, 50, " + p.alpha + ")";
                        ctx.shadowBlur = 10; ctx.shadowColor = '#ff3300';
                        ctx.fill();
                    }
                    requestAnimationFrame(animateParticles);
                }
                animateParticles();
        
                let tapCount = 0;
                document.querySelector('.card')?.addEventListener('click', () => {
                    tapCount++;
                    setTimeout(() => { tapCount = 0; }, 500);
                    if (tapCount === 2) {
                        document.body.classList.toggle('light-mode');
                        tapCount = 0;
                    }
                    resetInactivityTimer();
                });
            </script>
        </body>
        </html>
        """
    }
}

struct ContentView: View {
    var body: some View {
        WebView()
            .edgesIgnoringSafeArea(.all)
            .preferredColorScheme(.dark)
    }
}
