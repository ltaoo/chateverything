
import Foundation
import AVFoundation
import QCloudRealTTS

class PCMStreamPlayer {
    var engine: AVAudioEngine
    private var in_format: AVAudioFormat
    private var out_format: AVAudioFormat
    var player_node: AVAudioPlayerNode
    private var converter: AVAudioConverter
    private var tail = Data()
    
    init() {
        do {
            // 修改音频会话配置，支持播放和录音
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
		.playAndRecord, 
		mode: .default,
		options: [.defaultToSpeaker, .allowBluetooth]
	)
            try audioSession.setActive(true)
            
            self.engine = AVAudioEngine()
            player_node = AVAudioPlayerNode()
            in_format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: false)!
            out_format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
            converter = AVAudioConverter(from: in_format, to: out_format)!
            engine.attach(player_node)
            engine.connect(player_node, to: engine.outputNode, format: out_format)
            try engine.start()
            player_node.play()
        } catch {
            print("PCMStreamPlayer initialization error: \(error)")
            exit(-1)
        }
    }
    
    func put(data: Data) {
        print("[PCMStreamPlayer] Received data chunk: \(data.count) bytes")
        // 忽略空数据
        if data.count == 0 {
            print("[PCMStreamPlayer] Ignoring empty data chunk")
            return
        }
        
        var local_data = data
        tail.append(local_data)
        local_data = tail
        
        // 确保引擎和节点处于活动状态
        if !engine.isRunning {
            do {
                try engine.start()
                player_node.play()
                print("[PCMStreamPlayer] Restarted audio engine")
            } catch {
                print("[PCMStreamPlayer] Failed to restart audio engine: \(error)")
            }
        }
        
        if (tail.count % 2 == 1) {
            tail = local_data.subdata(in: tail.count-1..<tail.count)
            local_data.count = local_data.count - 1
        } else {
            tail = Data()
        }
        if (local_data.count == 0) {
            print("[PCMStreamPlayer] Warning: Empty data chunk")
            return
        }
        let in_buffer = AVAudioPCMBuffer(pcmFormat: in_format, frameCapacity: AVAudioFrameCount(local_data.count) / in_format.streamDescription.pointee.mBytesPerFrame)!
        in_buffer.frameLength = in_buffer.frameCapacity
        if let channels = in_buffer.int16ChannelData {
            let int16arr = local_data.withUnsafeBytes {
                Array(UnsafeBufferPointer<Int16>(start: $0.baseAddress!.assumingMemoryBound(to: Int16.self), count: local_data.count / MemoryLayout<Int16>.size))
            }
            for i in 0..<Int(in_buffer.frameLength) {
                channels[0][i] = int16arr[i]
            }
        }
        let out_buffer = AVAudioPCMBuffer(pcmFormat: out_format, frameCapacity: in_buffer.frameCapacity)!
        do {
            try converter.convert(to: out_buffer, from: in_buffer)
            print("[PCMStreamPlayer] Successfully converted and scheduled buffer")
        } catch {
            print("[PCMStreamPlayer] Conversion error: \(error)")
            exit(-1)
        }
        player_node.scheduleBuffer(out_buffer)
    }
    
    deinit {
        print("[PCMStreamPlayer] Cleaning up resources")
        player_node.stop()
        engine.stop()
    }
}
