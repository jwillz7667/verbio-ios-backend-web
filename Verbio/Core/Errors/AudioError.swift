//
//  AudioError.swift
//  Verbio
//
//  Audio-specific error types
//

import Foundation

// MARK: - Audio Error

/// Errors related to audio recording and playback
enum AudioError: LocalizedError, Equatable {

    // MARK: - Recording Errors

    case microphoneAccessDenied
    case microphoneAccessRestricted
    case recordingFailed(reason: String)
    case recordingTooShort
    case recordingTooLong(maxSeconds: Int)
    case noRecordingInProgress
    case recordingAlreadyInProgress

    // MARK: - Playback Errors

    case playbackFailed(reason: String)
    case invalidAudioData
    case audioFileNotFound
    case audioDownloadFailed
    case playbackAlreadyInProgress
    case noPlaybackInProgress

    // MARK: - Format Errors

    case unsupportedFormat
    case encodingFailed
    case decodingFailed

    // MARK: - Session Errors

    case audioSessionSetupFailed(reason: String)
    case audioSessionInterrupted

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .microphoneAccessDenied:
            return "Microphone access was denied."

        case .microphoneAccessRestricted:
            return "Microphone access is restricted."

        case .recordingFailed(let reason):
            return "Recording failed: \(reason)"

        case .recordingTooShort:
            return "Recording is too short. Please record at least 1 second of audio."

        case .recordingTooLong(let maxSeconds):
            return "Recording exceeds maximum duration of \(maxSeconds) seconds."

        case .noRecordingInProgress:
            return "No recording is currently in progress."

        case .recordingAlreadyInProgress:
            return "A recording is already in progress."

        case .playbackFailed(let reason):
            return "Playback failed: \(reason)"

        case .invalidAudioData:
            return "The audio data is invalid or corrupted."

        case .audioFileNotFound:
            return "The audio file could not be found."

        case .audioDownloadFailed:
            return "Failed to download audio from server."

        case .playbackAlreadyInProgress:
            return "Audio playback is already in progress."

        case .noPlaybackInProgress:
            return "No audio playback is in progress."

        case .unsupportedFormat:
            return "The audio format is not supported."

        case .encodingFailed:
            return "Failed to encode audio data."

        case .decodingFailed:
            return "Failed to decode audio data."

        case .audioSessionSetupFailed(let reason):
            return "Failed to set up audio session: \(reason)"

        case .audioSessionInterrupted:
            return "Audio session was interrupted."
        }
    }

    var failureReason: String? {
        errorDescription
    }

    var recoverySuggestion: String? {
        switch self {
        case .microphoneAccessDenied, .microphoneAccessRestricted:
            return "Please enable microphone access in Settings > Privacy > Microphone."

        case .recordingFailed, .playbackFailed:
            return "Please try again. If the problem persists, restart the app."

        case .recordingTooShort:
            return "Hold the record button longer to capture more audio."

        case .recordingTooLong:
            return "Try recording a shorter message."

        case .recordingAlreadyInProgress, .noRecordingInProgress:
            return nil

        case .invalidAudioData, .unsupportedFormat, .encodingFailed, .decodingFailed:
            return "Please try recording again."

        case .audioFileNotFound, .audioDownloadFailed:
            return "Please check your internet connection and try again."

        case .playbackAlreadyInProgress, .noPlaybackInProgress:
            return nil

        case .audioSessionSetupFailed, .audioSessionInterrupted:
            return "Please close other apps using audio and try again."
        }
    }
}

// MARK: - Error Conversion

extension AudioError {
    /// Create an AudioError from any Error
    static func from(_ error: Error) -> AudioError {
        if let audioError = error as? AudioError {
            return audioError
        }

        return .recordingFailed(reason: error.localizedDescription)
    }
}
