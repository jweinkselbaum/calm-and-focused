import Foundation

struct SoundTrack: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let symbol: String
    let type: SoundType

    enum SoundType: String, Codable {
        case rain, vinyl, whiteNoise, brownNoise, ocean, wind, fireplace
    }

    static let library: [SoundTrack] = [
        SoundTrack(id: "rain",       name: "Rain",        symbol: "cloud.rain.fill",  type: .rain),
        SoundTrack(id: "vinyl",      name: "Vinyl",        symbol: "record.circle",    type: .vinyl),
        SoundTrack(id: "whiteNoise", name: "White Noise",  symbol: "waveform",         type: .whiteNoise),
        SoundTrack(id: "brownNoise", name: "Brown Noise",  symbol: "wave.3.right",     type: .brownNoise),
        SoundTrack(id: "ocean",      name: "Ocean",        symbol: "water.waves",      type: .ocean),
        SoundTrack(id: "wind",       name: "Wind",         symbol: "wind",             type: .wind),
        SoundTrack(id: "fireplace",  name: "Fireplace",    symbol: "flame.fill",       type: .fireplace),
    ]
}
