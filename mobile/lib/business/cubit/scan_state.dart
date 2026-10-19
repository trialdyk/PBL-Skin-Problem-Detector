import 'package:equatable/equatable.dart';
import 'package:pbl_skin_problem_detector/data/models/gea_result.dart';
import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';

enum ScanPhase {
  intro,
  capturing,
  uploading,
  confirming,
  interviewing,
  diagnosing,
  result,
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.fromBot,
    required this.text,
    this.editableKey,
  });

  final String id;
  final bool fromBot;
  final String text;
  final String? editableKey;

  @override
  List<Object?> get props => [id, fromBot, text, editableKey];
}

class ScanState extends Equatable {
  const ScanState({
    this.phase = ScanPhase.intro,
    this.session = const ScanSession(),
    this.currentAngle = SelfieAngle.front,
    this.interviewStep = 0,
    this.messages = const [],
    this.isTyping = false,
    this.errorMessage,
  });

  final ScanPhase phase;
  final ScanSession session;
  final SelfieAngle currentAngle;
  final int interviewStep;
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? errorMessage;

  GeaResult? get result => session.result;
  bool get hasAllPhotos => session.hasAllPhotos;

  ScanState copyWith({
    ScanPhase? phase,
    ScanSession? session,
    SelfieAngle? currentAngle,
    int? interviewStep,
    List<ChatMessage>? messages,
    bool? isTyping,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ScanState(
      phase: phase ?? this.phase,
      session: session ?? this.session,
      currentAngle: currentAngle ?? this.currentAngle,
      interviewStep: interviewStep ?? this.interviewStep,
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        phase,
        session,
        currentAngle,
        interviewStep,
        messages,
        isTyping,
        errorMessage,
      ];
}
