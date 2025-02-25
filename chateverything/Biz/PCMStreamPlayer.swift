import Foundation
import AVFoundation

class PCMStreamPlayer {
    private var engine: AVAudioEngine
    private var in_format: AVAudioFormat
    private var out_format: AVAudioFormat
    private var player_node: AVAudioPlayerNode
    private var converter: AVAudioConverter
    private var tail = Data()
    var onPlayComplete: (() -> Void)?
    
    init() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            self.engine = AVAudioEngine()
            player_node = AVAudioPlayerNode()
            in_format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: false)!
            out_format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
            converter = AVAudioConverter(from: in_format, to: out_format)!
            engine.attach(player_node)
            engine.connect(player_node, to: engine.outputNode, format: out_format)
            try engine.start()
            player_node.play()
        }catch {
            print("[PCMStreamPlayer]error: \(error)")
            exit(-1)
        }
    }
    
    func put(data: Data) {
        var local_data = data
        tail.append(local_data)
        local_data = tail
        if (tail.count % 2 == 1) {
            tail = local_data.subdata(in: tail.count-1..<tail.count)
            local_data.count = local_data.count - 1
        } else {
            tail = Data()
        }
        if (local_data.count == 0) {
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
        do{
            try converter.convert(to: out_buffer, from: in_buffer)
        }catch {
            exit(-1)
        }
        player_node.scheduleBuffer(out_buffer) {
            DispatchQueue.main.async { [weak self] in
                self?.onPlayComplete?()
            }
        }
    }
}
