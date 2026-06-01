import Foundation
import AVFoundation
import Observation

enum NoiseColor: Int, CaseIterable, Codable, Identifiable {
    case white = 0
    case pink = 1
    case brown = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .white: return "White"
        case .pink: return "Pink"
        case .brown: return "Brown"
        }
    }
}

/// Plain reference type holding the live synth parameters. Shared with the audio
/// render blocks, which run on the real-time render thread and must not touch the
/// `@MainActor`-isolated mixer. Float reads/writes are cheap and tolerant here.
private final class SynthParams: @unchecked Sendable {
    var engineGain: Float = 0
    var noiseGain: Float = 0
    var noiseColor: Int = NoiseColor.brown.rawValue
}

/// Two synthesized ambient beds for the in-flight focus experience: a jet-engine
/// drone and selectable white/pink/brown noise. Each layer has an independent gain;
/// a master volume scales the whole mix.
@MainActor
@Observable
final class AmbienceMixer {
    // MARK: Published mix state (bound to the UI)

    var masterVolume: Float { didSet { store("master", masterVolume); applyMaster() } }
    var engineGain: Float   { didSet { store("engine", engineGain); params.engineGain = engineGain } }
    var noiseGain: Float    { didSet { store("noise", noiseGain); params.noiseGain = noiseGain } }
    var noiseColor: NoiseColor { didSet { store("noiseColor", Float(noiseColor.rawValue)); params.noiseColor = noiseColor.rawValue } }

    /// Whether the mix is currently audible (engine running and faded in).
    private(set) var isActive: Bool = false

    // MARK: Audio graph

    private let engine = AVAudioEngine()
    private let params = SynthParams()
    private let synthFormat = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!

    private var noiseNode: AVAudioSourceNode?
    private var droneNode: AVAudioSourceNode?

    private var built = false
    private var fadeTask: Task<Void, Never>?

    private let defaults = UserDefaults.standard
    private func key(_ s: String) -> String { "ambience.\(s)" }
    private func store(_ s: String, _ v: Float) { defaults.set(v, forKey: key(s)) }
    private func load(_ s: String, _ fallback: Float) -> Float {
        defaults.object(forKey: key(s)) == nil ? fallback : defaults.float(forKey: key(s))
    }

    init() {
        masterVolume = 0
        engineGain = 0; noiseGain = 0
        noiseColor = .brown

        masterVolume = load("master", 0.7)
        engineGain = load("engine", 0.45)
        noiseGain = load("noise", 0.0)
        if defaults.object(forKey: key("noiseColor")) != nil {
            noiseColor = NoiseColor(rawValue: Int(load("noiseColor", 2))) ?? .brown
        }

        params.engineGain = engineGain
        params.noiseGain = noiseGain
        params.noiseColor = noiseColor.rawValue

        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleConfigurationChange() }
        }
    }

    // MARK: Lifecycle

    /// Builds the graph and starts the engine silently. Cheap to call repeatedly.
    func prepare() {
        build()
        guard !engine.isRunning else { return }
        engine.prepare()
        do { try engine.start() } catch {
            print("AmbienceMixer: engine failed to start — \(error)")
            return
        }
        engine.mainMixerNode.outputVolume = 0
    }

    /// Fades the mix in.
    func start() {
        prepare()
        guard engine.isRunning else { return }
        isActive = true
        applyGains()
        fade(to: masterVolume)
    }

    /// Fades out and stops the engine entirely.
    func stop() {
        isActive = false
        fadeTask?.cancel()
        let mixer = engine.mainMixerNode
        let startV = mixer.outputVolume
        fadeTask = Task { [engine] in
            let steps = 20
            for i in 0...steps {
                if Task.isCancelled { return }
                mixer.outputVolume = startV * (1 - Float(i) / Float(steps))
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
            engine.stop()
        }
    }

    private func handleConfigurationChange() {
        guard isActive else { return }
        if !engine.isRunning { try? engine.start() }
    }

    // MARK: Graph construction

    private func build() {
        guard !built else { return }
        built = true

        let noise = makeNoiseNode()
        engine.attach(noise)
        engine.connect(noise, to: engine.mainMixerNode, format: synthFormat)
        noiseNode = noise

        let drone = makeDroneNode()
        engine.attach(drone)
        engine.connect(drone, to: engine.mainMixerNode, format: synthFormat)
        droneNode = drone
    }

    private func applyGains() {
        params.engineGain = engineGain
        params.noiseGain = noiseGain
        params.noiseColor = noiseColor.rawValue
    }

    private func applyMaster() {
        guard isActive, engine.isRunning else { return }
        fadeTask?.cancel()
        engine.mainMixerNode.outputVolume = masterVolume
    }

    private func fade(to target: Float) {
        fadeTask?.cancel()
        let mixer = engine.mainMixerNode
        let startV = mixer.outputVolume
        fadeTask = Task {
            let steps = 24
            for i in 0...steps {
                if Task.isCancelled { return }
                let t = Float(i) / Float(steps)
                mixer.outputVolume = startV + (target - startV) * t
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
        }
    }

    // MARK: Synthesis nodes

    /// White / pink / brown noise generator (color selectable live via `params`).
    private func makeNoiseNode() -> AVAudioSourceNode {
        let params = self.params
        var rngL: UInt32 = 0x2545F491
        var rngR: UInt32 = 0x9E3779B1
        var pinkL = [Float](repeating: 0, count: 3)
        var pinkR = [Float](repeating: 0, count: 3)
        var brownL: Float = 0, brownR: Float = 0
        var gain: Float = 0

        func white(_ s: inout UInt32) -> Float {
            s ^= s << 13; s ^= s >> 17; s ^= s << 5
            return Float(Int32(bitPattern: s)) / Float(Int32.max)
        }
        func sample(_ s: inout UInt32, _ pink: inout [Float], _ brown: inout Float, _ color: Int) -> Float {
            let w = white(&s)
            switch color {
            case 0: // white
                return w * 0.25
            case 1: // pink (Paul Kellet, economy)
                pink[0] = 0.99765 * pink[0] + w * 0.0990460
                pink[1] = 0.96300 * pink[1] + w * 0.2965164
                pink[2] = 0.57000 * pink[2] + w * 1.0526913
                return (pink[0] + pink[1] + pink[2] + w * 0.1848) * 0.12
            default: // brown
                brown += w * 0.02
                brown = max(-1, min(1, brown)) * 0.998
                return brown * 3.0 * 0.5
            }
        }

        return AVAudioSourceNode(format: synthFormat) { _, _, frameCount, ablPtr in
            let abl = UnsafeMutableAudioBufferListPointer(ablPtr)
            let color = params.noiseColor
            let target = params.noiseGain
            for frame in 0..<Int(frameCount) {
                gain += (target - gain) * 0.001
                let l = sample(&rngL, &pinkL, &brownL, color) * gain
                let r = sample(&rngR, &pinkR, &brownR, color) * gain
                if abl.count > 0 { abl[0].mData!.assumingMemoryBound(to: Float.self)[frame] = l }
                if abl.count > 1 { abl[1].mData!.assumingMemoryBound(to: Float.self)[frame] = r }
            }
            return noErr
        }
    }

    /// Jet-engine drone: low-passed brown noise with a slow breathing LFO.
    private func makeDroneNode() -> AVAudioSourceNode {
        let params = self.params
        let sampleRate: Float = 48_000
        var rngL: UInt32 = 0x1F123BB5
        var rngR: UInt32 = 0x6C8E9CF7
        var brownL: Float = 0, brownR: Float = 0
        var lpL: Float = 0, lpR: Float = 0
        var lfoPhase: Float = 0
        var gain: Float = 0
        let twoPi = Float.pi * 2

        func white(_ s: inout UInt32) -> Float {
            s ^= s << 13; s ^= s >> 17; s ^= s << 5
            return Float(Int32(bitPattern: s)) / Float(Int32.max)
        }
        func drone(_ s: inout UInt32, _ brown: inout Float, _ lp: inout Float) -> Float {
            brown += white(&s) * 0.02
            brown = max(-1, min(1, brown)) * 0.998
            lp += (brown - lp) * 0.02         // heavy low-pass → deep rumble
            return lp * 7.0 * 0.5
        }

        return AVAudioSourceNode(format: synthFormat) { _, _, frameCount, ablPtr in
            let abl = UnsafeMutableAudioBufferListPointer(ablPtr)
            let target = params.engineGain
            for frame in 0..<Int(frameCount) {
                gain += (target - gain) * 0.001
                lfoPhase += twoPi * 0.08 / sampleRate
                if lfoPhase > twoPi { lfoPhase -= twoPi }
                let amp = (0.8 + 0.2 * sin(lfoPhase)) * gain
                let l = max(-1, min(1, drone(&rngL, &brownL, &lpL) * amp))
                let r = max(-1, min(1, drone(&rngR, &brownR, &lpR) * amp))
                if abl.count > 0 { abl[0].mData!.assumingMemoryBound(to: Float.self)[frame] = l }
                if abl.count > 1 { abl[1].mData!.assumingMemoryBound(to: Float.self)[frame] = r }
            }
            return noErr
        }
    }
}
