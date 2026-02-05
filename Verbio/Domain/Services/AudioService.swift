//
//  AudioService.swift
//  Verbio
//
//  Audio recording and playback service
//

import Foundation
import AVFoundation

// MARK: - Audio Service Protocol

protocol AudioServiceProtocol: Sendable {
    /// Current recording state
    var isRecording: Bool { get async }

    /// Current playback state
    var isPlaying: Bool { get async }

    /// Current audio level (0.0 - 1.0) during recording
    var audioLevel: Float { get async }

    /// Current recording duration in seconds
    var recordingDuration: TimeInterval { get async }

    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool

    /// Start recording audio
    func startRecording() async throws

    /// Stop recording and return audio data
    func stopRecording() async throws -> Data

    /// Cancel the current recording
    func cancelRecording() async

    /// Play audio from data
    func playAudio(data: Data) async throws

    /// Play audio from URL
    func playAudio(url: URL) async throws

    /// Stop audio playback
    func stopPlayback() async

    /// Stream to observe audio levels during recording
    func audioLevelStream() -> AsyncStream<Float>
}

// MARK: - Audio Service Implementation

actor AudioService: AudioServiceProtocol {

    // MARK: - Constants

    private let maxRecordingDuration: TimeInterval = 60.0 // 60 seconds max
    private let minRecordingDuration: TimeInterval = 0.5  // 0.5 seconds min
    private let audioSampleRate: Double = 16000.0         // Whisper optimal
    private let levelMeteringInterval: TimeInterval = 0.05 // 50ms

    // MARK: - Properties

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?
    private var levelMeteringTask: Task<Void, Never>?
    private var levelContinuation: AsyncStream<Float>.Continuation?

    private var _isRecording = false
    private var _isPlaying = false
    private var _audioLevel: Float = 0.0
    private var recordingStartTime: Date?

    // MARK: - Public Properties

    var isRecording: Bool { _isRecording }
    var isPlaying: Bool { _isPlaying }
    var audioLevel: Float { _audioLevel }

    var recordingDuration: TimeInterval {
        guard let startTime = recordingStartTime, _isRecording else { return 0 }
        return Date().timeIntervalSince(startTime)
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Microphone Permission

    func requestMicrophonePermission() async -> Bool {
        let status = AVAudioApplication.shared.recordPermission

        switch status {
        case .granted:
            return true

        case .denied:
            return false

        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }

        @unknown default:
            return false
        }
    }

    // MARK: - Recording

    func startRecording() async throws {
        // Check if already recording
        guard !_isRecording else {
            throw AudioError.recordingAlreadyInProgress
        }

        // Check microphone permission
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            throw AudioError.microphoneAccessDenied
        }

        // Configure audio session for recording
        try await configureAudioSession(for: .recording)

        // Create recording URL
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "recording_\(UUID().uuidString).wav"
        recordingURL = tempDir.appendingPathComponent(filename)

        guard let url = recordingURL else {
            throw AudioError.recordingFailed(reason: "Could not create recording file")
        }

        // Recording settings optimized for Whisper
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: audioSampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()

            guard audioRecorder?.record() == true else {
                throw AudioError.recordingFailed(reason: "Recorder failed to start")
            }

            _isRecording = true
            recordingStartTime = Date()

            // Start level metering
            startLevelMetering()

        } catch {
            throw AudioError.recordingFailed(reason: error.localizedDescription)
        }
    }

    func stopRecording() async throws -> Data {
        guard _isRecording, let recorder = audioRecorder else {
            throw AudioError.noRecordingInProgress
        }

        // Check minimum duration
        let duration = recordingDuration
        if duration < minRecordingDuration {
            cancelRecording()
            throw AudioError.recordingTooShort
        }

        // Stop recording
        recorder.stop()
        stopLevelMetering()
        _isRecording = false
        recordingStartTime = nil

        // Read the recorded audio data
        guard let url = recordingURL else {
            throw AudioError.recordingFailed(reason: "Recording URL not available")
        }

        do {
            let audioData = try Data(contentsOf: url)

            // Cleanup
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
            audioRecorder = nil

            return audioData

        } catch {
            throw AudioError.recordingFailed(reason: "Could not read recording: \(error.localizedDescription)")
        }
    }

    func cancelRecording() {
        audioRecorder?.stop()
        stopLevelMetering()
        _isRecording = false
        recordingStartTime = nil

        // Cleanup
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        audioRecorder = nil
        _audioLevel = 0.0
    }

    // MARK: - Playback

    func playAudio(data: Data) async throws {
        guard !_isPlaying else {
            throw AudioError.playbackAlreadyInProgress
        }

        try await configureAudioSession(for: .playback)

        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()

            guard audioPlayer?.play() == true else {
                throw AudioError.playbackFailed(reason: "Player failed to start")
            }

            _isPlaying = true

            // Wait for playback to complete
            await waitForPlaybackCompletion()

        } catch let error as AudioError {
            throw error
        } catch {
            throw AudioError.playbackFailed(reason: error.localizedDescription)
        }
    }

    func playAudio(url: URL) async throws {
        guard !_isPlaying else {
            throw AudioError.playbackAlreadyInProgress
        }

        // Download audio if remote URL
        let audioData: Data
        if url.isFileURL {
            do {
                audioData = try Data(contentsOf: url)
            } catch {
                throw AudioError.audioFileNotFound
            }
        } else {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw AudioError.audioDownloadFailed
                }
                audioData = data
            } catch let error as AudioError {
                throw error
            } catch {
                throw AudioError.audioDownloadFailed
            }
        }

        try await playAudio(data: audioData)
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        _isPlaying = false
    }

    // MARK: - Audio Level Stream

    func audioLevelStream() -> AsyncStream<Float> {
        AsyncStream { continuation in
            Task { [weak self] in
                await self?.setLevelContinuation(continuation)
            }

            continuation.onTermination = { @Sendable _ in
                Task { [weak self] in
                    await self?.clearLevelContinuation()
                }
            }
        }
    }

    private func setLevelContinuation(_ continuation: AsyncStream<Float>.Continuation) {
        self.levelContinuation = continuation
    }

    private func clearLevelContinuation() {
        levelContinuation = nil
    }

    // MARK: - Private Helpers

    private enum AudioSessionMode {
        case recording
        case playback
    }

    private func configureAudioSession(for mode: AudioSessionMode) async throws {
        let session = AVAudioSession.sharedInstance()

        do {
            switch mode {
            case .recording:
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])

            case .playback:
                try session.setCategory(.playback, mode: .default)
            }

            try session.setActive(true)

        } catch {
            throw AudioError.audioSessionSetupFailed(reason: error.localizedDescription)
        }
    }

    private func startLevelMetering() {
        levelMeteringTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }

                await self.updateAudioLevel()

                try? await Task.sleep(nanoseconds: UInt64(self.levelMeteringInterval * 1_000_000_000))
            }
        }
    }

    private func updateAudioLevel() {
        guard let recorder = audioRecorder, _isRecording else {
            _audioLevel = 0.0
            return
        }

        recorder.updateMeters()

        // Get average power in dB and convert to 0-1 range
        let averagePower = recorder.averagePower(forChannel: 0)

        // Normalize: -160 dB (silence) to 0 dB (max)
        // Map to 0.0 - 1.0 range with emphasis on speech levels (-40 to 0 dB)
        let normalizedLevel = max(0, (averagePower + 60) / 60)
        _audioLevel = min(1.0, normalizedLevel)

        // Send to stream
        levelContinuation?.yield(_audioLevel)
    }

    private func stopLevelMetering() {
        levelMeteringTask?.cancel()
        levelMeteringTask = nil
        _audioLevel = 0.0
        levelContinuation?.yield(0.0)
    }

    private func waitForPlaybackCompletion() async {
        guard let player = audioPlayer else { return }

        // Poll for completion
        while player.isPlaying {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        _isPlaying = false
        audioPlayer = nil
    }
}
