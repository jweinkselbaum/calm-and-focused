import AVFoundation
import Foundation

@MainActor
final class SoundEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private var players: [UUID: AVAudioPlayerNode] = [:]
    private var buffers: [UUID: AVAudioPCMBuffer] = [:]

    private let sampleRate: Double = 44100
    private let bufferDuration: Double = 10.0

    @Published var tracks: [SoundTrack] = SoundTrack.all

    init() {
        setupEngine()
    }

    private func setupEngine() {
        for track in tracks {
            let player = AVAudioPlayerNode()
            engine.attach(player)

            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
            let buffer = generateBuffer(for: track.type, format: format)

            engine.connect(player, to: engine.mainMixerNode, format: format)
            players[track.id] = player
            buffers[track.id] = buffer
        }

        do {
            try engine.start()
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }

    private func generateBuffer(for type: SoundTrack.SoundType, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * bufferDuration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]

        switch type {
        case .whiteNoise:
            fillWhiteNoise(left: left, right: right, count: Int(frameCount))
        case .rain:
            fillRain(left: left, right: right, count: Int(frameCount))
        case .vinyl:
            fillVinyl(left: left, right: right, count: Int(frameCount))
        }

        return buffer
    }

    private func fillWhiteNoise(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, count: Int) {
        for i in 0..<count {
            let sample = Float.random(in: -0.25...0.25)
            left[i] = sample
            right[i] = Float.random(in: -0.25...0.25)
        }
    }

    private func fillRain(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, count: Int) {
        // Pink noise approximation via IIR filtering of white noise
        var b0L: Float = 0, b1L: Float = 0, b2L: Float = 0
        var b3L: Float = 0, b4L: Float = 0, b5L: Float = 0, b6L: Float = 0
        var b0R: Float = 0, b1R: Float = 0, b2R: Float = 0
        var b3R: Float = 0, b4R: Float = 0, b5R: Float = 0, b6R: Float = 0

        for i in 0..<count {
            let wL = Float.random(in: -1...1)
            b0L = 0.99886 * b0L + wL * 0.0555179
            b1L = 0.99332 * b1L + wL * 0.0750759
            b2L = 0.96900 * b2L + wL * 0.1538520
            b3L = 0.86650 * b3L + wL * 0.3104856
            b4L = 0.55000 * b4L + wL * 0.5329522
            b5L = -0.7616 * b5L - wL * 0.0168980
            b6L = wL * 0.115926
            left[i] = (b0L + b1L + b2L + b3L + b4L + b5L + b6L + wL * 0.5362) * 0.11

            let wR = Float.random(in: -1...1)
            b0R = 0.99886 * b0R + wR * 0.0555179
            b1R = 0.99332 * b1R + wR * 0.0750759
            b2R = 0.96900 * b2R + wR * 0.1538520
            b3R = 0.86650 * b3R + wR * 0.3104856
            b4R = 0.55000 * b4R + wR * 0.5329522
            b5R = -0.7616 * b5R - wR * 0.0168980
            b6R = wR * 0.115926
            right[i] = (b0R + b1R + b2R + b3R + b4R + b5R + b6R + wR * 0.5362) * 0.11
        }
    }

    private func fillVinyl(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, count: Int) {
        // High-frequency crackle: white noise passed through a high-pass-like filter + sparse impulses
        var prevL: Float = 0
        var prevR: Float = 0
        let alpha: Float = 0.95

        for i in 0..<count {
            let noiseL = Float.random(in: -1...1)
            let noiseR = Float.random(in: -1...1)

            // High-pass filter
            let hpL = alpha * (prevL + noiseL - (i > 0 ? left[i - 1] : 0))
            let hpR = alpha * (prevR + noiseR - (i > 0 ? right[i - 1] : 0))
            prevL = hpL
            prevR = hpR

            // Sparse crackle impulses
            let crackle: Float = Float.random(in: 0...1) > 0.9995 ? Float.random(in: -0.6...0.6) : 0

            left[i] = hpL * 0.015 + crackle
            right[i] = hpR * 0.015 + crackle * Float.random(in: 0.8...1.0)
        }
    }

    func setActive(_ active: Bool, for trackID: UUID) {
        guard let player = players[trackID], let buffer = buffers[trackID] else { return }

        if active {
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.play()
        } else {
            player.stop()
        }

        if let index = tracks.firstIndex(where: { $0.id == trackID }) {
            tracks[index].isActive = active
        }
    }

    func setVolume(_ volume: Double, for trackID: UUID) {
        players[trackID]?.volume = Float(volume)
        if let index = tracks.firstIndex(where: { $0.id == trackID }) {
            tracks[index].volume = volume
        }
    }
}
