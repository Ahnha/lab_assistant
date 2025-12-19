import 'step_kind.dart';
import 'step_status.dart';
import 'checklist_item.dart';

enum TimerState { idle, running, paused, finished }

class ProcedureStep {
  final String id;
  final StepKind kind;
  final String title;
  final String? description;
  final int order;
  StepStatus status;

  // For checklist
  List<ChecklistItem>? items;

  // For timer
  int? timerSeconds; // Initial duration in seconds
  int? remainingSeconds; // Current remaining time
  TimerState? timerState; // Current timer state
  DateTime? timerStartedAt; // When timer was started (optional)

  // For inputNumber
  String? unit;
  num? value;

  // For ingredient navigation
  String? ingredientSectionId; // e.g., "phase:pA" or "soap:oils"
  String? ingredientSectionLabel; // e.g., "Phase A" or "Oils"

  ProcedureStep({
    required this.id,
    required this.kind,
    required this.title,
    this.description,
    required this.order,
    this.status = StepStatus.todo,
    this.items,
    this.timerSeconds,
    this.remainingSeconds,
    this.timerState,
    this.timerStartedAt,
    this.unit,
    this.value,
    this.ingredientSectionId,
    this.ingredientSectionLabel,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'title': title,
      'description': description,
      'order': order,
      'status': status.name,
      'items': items?.map((item) => item.toJson()).toList(),
      'timerSeconds': timerSeconds,
      'remainingSeconds': remainingSeconds,
      'timerState': timerState?.name,
      'timerStartedAt': timerStartedAt?.toIso8601String(),
      'unit': unit,
      'value': value,
      'ingredientSectionId': ingredientSectionId,
      'ingredientSectionLabel': ingredientSectionLabel,
    };
  }

  factory ProcedureStep.fromJson(Map<String, dynamic> json) {
    TimerState? parseTimerState(String? value) {
      if (value == null) return null;
      try {
        return TimerState.values.firstWhere((e) => e.name == value);
      } catch (e) {
        return null;
      }
    }

    DateTime? parseDateTime(String? value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    return ProcedureStep(
      id: json['id'] as String,
      kind: StepKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => StepKind.instruction,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      order: json['order'] as int,
      status: StepStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StepStatus.todo,
      ),
      items: json['items'] != null
          ? (json['items'] as List)
                .map(
                  (item) =>
                      ChecklistItem.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : null,
      timerSeconds: json['timerSeconds'] as int?,
      remainingSeconds: json['remainingSeconds'] as int?,
      timerState: parseTimerState(json['timerState'] as String?),
      timerStartedAt: parseDateTime(json['timerStartedAt'] as String?),
      unit: json['unit'] as String?,
      value: json['value'] as num?,
      ingredientSectionId: json['ingredientSectionId'] as String?,
      ingredientSectionLabel: json['ingredientSectionLabel'] as String?,
    );
  }
}
