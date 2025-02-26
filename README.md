# meeting_assistant

## Architecture Diagram
```
[Microphone] → [Audio Recorder] → (Local Storage)
                          ↓
[Speech-to-Text] → [Transcript] → [DeepSeek Summary]
                                                                          
                                     ↓
                               [User Interface]
```

## Features
- [x] **Speech-to-Text**
  - Real-time streaming recognition
  - Speaker diarization (2-6 speakers)
  - Google Cloud Speech API integration
- [x] **Audio Recording**
  - AAC format recording
  - Permission handling
  - Local storage management
- [x] **AI-Powered Summary**
  - Action item extraction
  - Decision highlighting
  - Speaker identification
- [x] **Translation**
  - Multi-language support
  - Google Translate API
  - Target languages: EN, ES, FR, DE, ZH, JA
- [ ] **User Interface**
  - Real-time transcript display
  - Recording controls
  - Summary/translation tabs

## Key Technologies
- Flutter Framework
- Google Speech-to-Text API
- Google Translate API
- DeepSeek AI
- Flutter Sound (audio processing)
- Permission Handler (access control)

## Development Process
1. **Core Functionality**
   - Audio recording & storage
   - Speech recognition pipeline
   - AI summary generation
2. **UI Implementation**
   - Real-time transcript stream
   - Post-meeting analysis view
3. **Optimization**
   - Background processing
   - Error handling
   - Performance tuning

## Platform Support
- Android (min SDK 21)
- iOS (min iOS 11)


