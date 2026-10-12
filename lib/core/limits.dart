/// Lengths the app allows for what people type. Each is at or below the
/// matching limit in `firebase/firestore.rules`, which enforces them on the
/// server; keep the two in step.
abstract final class Limits {
  /// A person's name (the server allows up to 80).
  static const name = 40;

  /// One text message (server: 2000).
  static const message = 2000;

  /// A teacher's note on a lesson (server: 2000).
  static const lessonNote = 2000;

  /// Extra details in a report (server: 1000).
  static const reportDetails = 1000;

  /// An admin's reason for turning down an application (server: 1000).
  static const declineReason = 1000;

  /// An admin's note on why an account was paused (server: 500).
  static const pauseReason = 500;

  /// A free-text answer in the teacher application.
  static const applicationAnswer = 500;
}
