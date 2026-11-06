import 'package:flutter/foundation.dart';
import 'cureando_models.dart';

/// Only local test profiles, never an authentication mechanism for Supabase.
@immutable
class LocalStaffProfile {
  const LocalStaffProfile({
    required this.id,
    required this.institutionId,
    required this.role,
  });
  final String id;
  final String institutionId;
  final OrientationRole role;
}

@immutable
class InternalNoteView {
  const InternalNoteView({
    required this.id,
    required this.body,
    required this.createdAt,
  });
  final String id;
  final String body;
  final DateTime createdAt;
}

@immutable
class StaffCaseDetailView {
  StaffCaseDetailView({
    required this.studentView,
    required List<InternalNoteView> internalNotes,
  }) : internalNotes = List<InternalNoteView>.unmodifiable(internalNotes);
  final StudentCaseDetailView studentView;
  final List<InternalNoteView> internalNotes;
}
