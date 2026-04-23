import AVFoundation
import Foundation

@MainActor
final class SoundEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private var players: [String: AVAudioPlayerNode] = [:]
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var pendingActive: Set<String> = []

    // Pulled out of the @MainActor class so nonisolated static methods can access them freely
    fileprivate enum K {
        static let sampleRate: Double = 44100
        static let bufferSeconds: Double = 20.0
        static let volumeCeiling: Float = 0.42
    }

    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: K.sampleRate, channels: 2)!
        for track in SoundTrack.library {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players[track.id] = player
        }
        try? engine.start()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let bufs = Self.buildBuffers()
            DispatchQueue.main.async { self?.receive(bufs) }
        }
    }

    private func receive(_ bufs: [String: AVAudioPCMBuffer]) {
        buffers = bufs
        for id in pendingActive {
            scheduleLoop(id: id)
        }
        pendingActive.removeAll()
    }

    func setActive(_ active: Bool, for id: String) {
        guard let player = players[id] else { return }
        if active {
            if buffers[id] != nil {
                scheduleLoop(id: id)
            } else {
                pendingActive.insert(id)
            }
        } else {
            pendingActive.remove(id)
            player.stop()
        }
    }

    func setVolume(_ volume: Double, for id: String) {
        players[id]?.volume = Float(volume) * K.volumeCeiling
    }

    private func scheduleLoop(id: String) {
        guard let player = players[id], let buf = buffers[id] else { return }
        player.scheduleBuffer(buf, at: nil, options: .loops)
        player.play()
    }

    // MARK: - Buffer generation (runs off main thread)

    nonisolated private static func buildBuffers() -> [String: AVAudioPCMBuffer] {
        let format = AVAudioFormat(standardFormatWithSampleRate: K.sampleRate, channels: 2)!
        var result: [String: AVAudioPCMBuffer] = [:]
        for track in SoundTrack.library {
            result[track.id] = makeBuffer(type: track.type, format: format)
        }
        return result
    }

    nonisolated private static func makeBuffer(type: SoundTrack.SoundType, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(K.sampleRate * K.bufferSeconds)
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buf.frameLength = frameCount
        let L = buf.floatChannelData![0]
        let R = buf.floatChannelData![1]
        let n = Int(frameCount)
        switch type {
        case .rain:       fillRain(L: L, R: R, n: n)
        case .vinyl:      fillVinyl(L: L, R: R, n: n)
        case .whiteNoise: fillWhiteNoise(L: L, R: R, n: n)
        case .brownNoise: fillBrownNoise(L: L, R: R, n: n)
        case .ocean:      fillOcean(L: L, R: R, n: n)
        case .wind:       fillWind(L: L, R: R, n: n)
        case .fireplace:  fillFireplace(L: L, R: R, n: n)
        }
        return buf
    }

    // MARK: Synthesis

    nonisolated private static func fillWhiteNoise(L: UnsafeMutablePointer<Float>, R: UnsafeMutablePointer<Float>, n: Int) {
        for i in 0..<n {
            L[i] = Float.random(in: -0.12...0.12)
            R[i] = Float.random(in: -0.12...0.12)
        }
    }

    nonisolated private static func fillRain(L: UnsafeMutablePointer<Float>, R: UnsafeMutablePointer<Float>, n: Int) {
        // Pink noise base via Paul Kellet's method + slow intensity LFO + short reverb tail
        var b0L: Float = 0, b1L: Float = 0, b2L: Float = 0, b3L: Float = 0, b4L: Float = 0, b5L: Float = 0, b6L: Float = 0
        var b0R: Float = 0, b1R: Float = 0, b2R: Float = 0, b3R: Float = 0, b4R: Float = 0, b5R: Float = 0, b6R: Float = 0

        // Short reverb delay line (50 ms) to add "surface" character
        let delayLen = Int(K.sampleRate * 0.05)
        var dL = [Float](repeating: 0, count: delayLen)
        var dR = [Float](repeating: 0, count: delayLen)
        var dIdx = 0

        let lfoPhase = Float.random(in: 0...(.pi * 2))

        for i in 0..<n {
            let t = Float(i) / Float(K.sampleRate)
            let lfo = 0.68 + 0.32 * sin(2 * .pi * 0.18 * t + lfoPhase)

            let wL = Float.random(in: -1...1)
            b0L = 0.99886 * b0L + wL * 0.0555179
            b1L = 0.99332 * b1L + wL * 0.0750759
            b2L = 0.96900 * b2L + wL * 0.1538520
            b3L = 0.86650 * b3L + wL * 0.3104856
            b4L = 0.55000 * b4L + wL * 0.5329522
            b5L = -0.7616 * b5L - wL * 0.0168980
            b6L = wL * 0.115926
            let pinkL = (b0L + b1L + b2L + b3L + b4L + b5L + b6L + wL * 0.5362) * 0.052

            let wR = Float.random(in: -1...1)
            b0R = 0.99886 * b0R + wR * 0.0555179
            b1R = 0.99332 * b1R + wR * 0.0750759
            b2R = 0.96900 * b2R + wR * 0.1538520
            b3R = 0.86650 * b3R + wR * 0.3104856
            b4R = 0.55000 * b4R + wR * 0.5329522
            b5R = -0.7616 * b5R - wR * 0.0168980
            b6R = wR * 0.115926
            let pinkR = (b0R + b1R + b2R + b3R + b4R + b5R + b6R + wR * 0.5362) * 0.052

            let outL = pinkL * lfo + dL[dIdx] * 0.28
            let outR = pinkR * lfo + dR[dIdx] * 0.28
            dL[dIdx] = pinkL
            dR[dIdx] = pinkR
            dIdx = (dIdx + 1) % delayLen

            L[i] = outL
            R[i] = outR
        }
    }

    nonisolated private static func fillVinyl(L: UnsafeMutablePointer<Float>, R: UnsafeMutablePointer<Float>, n: Int) {
        var prevInL: Float = 0, prevOutL: Float = 0
        var prevInR: Float = 0, prevOutR: Float = 0
        let alpha: Float = 0.92

        for i in 0..<n {
            let wL = Float.random(in: -1...1)
            let wR = Float.random(in: -1...1)
            let hpL = alpha * (prevOutL + wL - prevInL)
            let hpR = alpha * (prevOutR + wR - prevInR)
            prevOutL = hpL; prevInL = wL
            prevOutR = hpR; prevInR = wR

            let crackle: Float = Float.random(in: 0...1) > 0.9995 ? Float.random(in: -0.55...0.55) : 0
            L[i] = hpL * 0.007 + crackle
            R[i] = hpR * 0.007 + crackle * Float.random(in: 0.8...1.0)
        }
    }

    nonisolated private static func fillBrownNoise(L: UnsafeMutablePointer<Float>, R: UnsafeMutablePointer<Float>, n: Int) {
        var runL: Float = 0, runR: Float = 0
        for i in 0..<n {
            runL = (runL + Float.random(in: -1...1)).clamped(to: -16...16)
            runR = (runR + Float.random(in: -1...1)).clamped(to: -16...16)
            L[i] = runL * 0.0028
            R[i] = runR * 0.0028
        }
    }

    nonisolated private static func fillOcean(L: UnsafeMutablePointer<Float>, R: UnsafeMutablePointer<Float>, n: Int) {
        var lpL: Float = 0, lpR: Float = 0
        let lp: Float = 0.005
        let phase = Float.random(in: 0...(.pi * 2))

        for i in 0..<n {
            let t = Float(i) / Float(K.sampleRate)
            // Slow wave swell (0.08 Hz ≈ 12 s per wave) + texture modulation
            let swell   = 0.5 + 0.5 * sin(2 * .pi * 0.08 * t + phase)
            let texture = 0.75 + 0.25 * sin(2 * .pi * 0.35 * t + 1.1)

            lpL += lp * (Float.random(in: -1...1) - lpL)
            lpR += lp * (Float.random(in: -1...1) - lpR)

            L[i] = lpL * swell * texture * 9.0
            R[i] = lpR * swell * texture * 9.0
        }
    }

    nonisolated private static func fillWind(L: UnsafeMutablePointer<Float>, R: UnsafeMutablePointer<Float>, n: Int) {
        // Two-stage lowpass → subtract → bandpass character around 300–900 Hz
        var lp1L: Float = 0, lp2L: Float = 0
        var lp1R: Float = 0, lp2R: Float = 0
        let a: Float = 0.06
        let phase = Float.random(in: 0...(.pi * 2))

        for i in 0..<n {
            let t = Float(i) / Float(K.sampleRate)
            let lfo = Float(0.55 + 0.45 * sin(2 * .pi * 0.22 * t + phase))

            let wL = Float.random(in: -1...1)
            let wR = Float.random(in: -1...1)
            lp1L += a * (wL - lp1L); lp2L += a * (lp1L - lp2L)
            lp1R += a * (wR - lp1R); lp2R += a * (lp1R - lp2R)

            L[i] = (lp1L - lp2L) * lfo * 0.5
            R[i] = (lp1R - lp2R) * lfo * 0.5
        }
    }

    nonisolated private static func fillFireplace(L: UnsafeMutablePointer<Float>, R: UnsafeMutablePointer<Float>, n: Int) {
        var lpL: Float = 0, lpR: Float = 0
        let lp: Float = 0.018
        let phase = Float.random(in: 0...(.pi * 2))

        for i in 0..<n {
            let t = Float(i) / Float(K.sampleRate)
            let flicker = Float(0.5 + 0.5 * sin(2 * .pi * 0.45 * t + phase))
                        * Float(0.75 + 0.25 * sin(2 * .pi * 1.1 * t))

            lpL += lp * (Float.random(in: -1...1) - lpL)
            lpR += lp * (Float.random(in: -1...1) - lpR)

            let crackle: Float = Float.random(in: 0...1) > 0.9982 ? Float.random(in: -0.4...0.4) : 0
            L[i] = lpL * flicker * 2.8 + crackle * 0.5
            R[i] = lpR * flicker * 2.8 + crackle * Float.random(in: 0.75...1.0) * 0.5
        }
    }
}

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        max(range.lowerBound, min(range.upperBound, self))
    }
}
