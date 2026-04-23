import Foundation

struct SoundTrack: Identifiable {
    let id: UUID
    let name: String
    let symbol: String
    let type: SoundType
    var volume: Double = 0.5
    var isActive: Bool = false

    enum SoundType {
        case rain, vinyl, whiteNoise
    }

    static let all: [SoundTrack] = [
        SoundTrack(id: UUID(), name: "Rain", symbol: "cloud.rain.fill", type: .rain),
        SoundTrack(id: UUID(), name: "Vinyl", symbol: "record.circle", type: .vinyl),
        SoundTrack(id: UUID(), name: "White Noise", symbol: "waveform", type: .whiteNoise),
    ]
}
