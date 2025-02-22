import SwiftUI
import Foundation
import AVFoundation

// 定义词汇数据结构
struct VocabularyItem: Codable {
    let name: String
    let trans: [String]
    let usphone: String
    let ukphone: String
}

// 音频播放器类
class AudioPlayer: ObservableObject {
    private var player: AVPlayer?
    @Published var isMuted: Bool = false
    @Published var volumeWarning: Bool = false
    
    init() {
        // 初始化时检查音量状态
        checkVolumeStatus()
        
        // 添加音量变化通知监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleVolumeChange),
            name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil
        )
    }
    
    func checkVolumeStatus() {
        let audioSession = AVAudioSession.sharedInstance()
        let volume = audioSession.outputVolume
        
        // 检查是否静音或音量太低
        isMuted = audioSession.outputVolume < 0.1
        volumeWarning = isMuted
        
        print("Current device volume: \(volume)")
    }
    
    @objc func handleVolumeChange(notification: NSNotification) {
        checkVolumeStatus()
    }
    
    func playAudio(word: String) {
        // 播放前检查音量
        checkVolumeStatus()
        
        print("Attempting to play audio for word: \(word)")
        
        guard let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Failed to encode word: \(word)")
            return
        }
        
        let urlString = "https://dict.youdao.com/dictvoice?audio=\(encodedWord)&type=2"
        guard let url = URL(string: urlString) else {
            print("Failed to create URL from string: \(urlString)")
            return
        }
        
        print("Created URL: \(url)")
        
        // 先尝试预加载音频数据
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error loading audio data: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
                print("Response headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data, !data.isEmpty else {
                print("No audio data received")
                return
            }
            
            print("Received audio data of size: \(data.count) bytes")
            
            // 在主线程创建和播放
            DispatchQueue.main.async {
                let playerItem = AVPlayerItem(url: url)
                self?.player = AVPlayer(playerItem: playerItem)
                self?.player?.volume = 1.0
                
                // 如果音量太低，显示警告但仍继续播放
                if self?.isMuted == true {
                    self?.volumeWarning = true
                }
                
                self?.player?.play()
                
                print("Audio playback initiated")
            }
        }.resume()
    }
    
    func cleanup() {
        // 停止播放
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        
        // 移除通知观察者
        NotificationCenter.default.removeObserver(self)
        
        print("AudioPlayer cleaned up")
    }
    
    deinit {
        cleanup()
    }
}

struct Vocabulary: View {
    let filepath: String
    var path: NavigationPath
    var store: ChatStore
    
    @State private var vocabularies: [VocabularyItem] = []
    @State private var currentIndex: Int = 0
    @StateObject private var audioPlayer = AudioPlayer()
    
    // 加载词汇数据
    private func loadVocabulary() {
        if let bundlePath = Bundle.main.path(forResource: "CET4_T", ofType: "json", inDirectory: "chateverything/dicts") {
            print("Found file at: \(bundlePath)")
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: bundlePath))
                vocabularies = try JSONDecoder().decode([VocabularyItem].self, from: data)
                print("Successfully loaded \(vocabularies.count) vocabulary items")
            } catch {
                print("Error loading vocabulary: \(error)")
            }
        } else {
            // 尝试不同的路径组合来定位文件
            print("Trying alternative paths...")
            let possiblePaths = [
                "dicts",
                "chateverything/dicts",
                ""
            ]
            
            for path in possiblePaths {
                if let url = Bundle.main.url(forResource: "CET4_T", withExtension: "json", subdirectory: path) {
                    print("Found file in directory: \(path)")
                    do {
                        let data = try Data(contentsOf: url)
                        vocabularies = try JSONDecoder().decode([VocabularyItem].self, from: data)
                        print("Successfully loaded \(vocabularies.count) vocabulary items")
                        return
                    } catch {
                        print("Error loading from \(path): \(error)")
                    }
                }
            }
            
            print("Could not find CET4_T.json in any expected location")
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if !vocabularies.isEmpty {
                // 显示单词
                Text(vocabularies[currentIndex].name)
                    .font(.system(size: 32, weight: .bold))
                    .onTapGesture {
                        // 点击单词播放音频
                        audioPlayer.playAudio(word: vocabularies[currentIndex].name)
                    }
                
                // 显示音标
                HStack(spacing: 20) {
                    VStack {
                        Text("US")
                            .font(.caption)
                        Text("/\(vocabularies[currentIndex].usphone)/")
                    }
                    VStack {
                        Text("UK")
                            .font(.caption)
                        Text("/\(vocabularies[currentIndex].ukphone)/")
                    }
                }
                .foregroundColor(.gray)
                
                // 显示翻译
                ForEach(vocabularies[currentIndex].trans, id: \.self) { translation in
                    Text(translation)
                        .font(.system(size: 18))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture {
            // 切换到下一个单词并播放音频
            currentIndex = (currentIndex + 1) % vocabularies.count
            audioPlayer.playAudio(word: vocabularies[currentIndex].name)
        }
        .onAppear {
            loadVocabulary()
        }
        .onDisappear {
            audioPlayer.cleanup()
        }
        // 添加音量警告提示
        .alert("音量提示", isPresented: $audioPlayer.volumeWarning) {
            Button("好的", role: .cancel) {
                audioPlayer.volumeWarning = false
            }
        } message: {
            Text("设备音量过低或已静音，请调高音量以听取单词发音。")
        }
    }
}
