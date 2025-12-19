class ChecklistItem {
  final String id;
  final String label;
  bool done;

  ChecklistItem({required this.id, required this.label, this.done = false});

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'done': done};
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      label: json['label'] as String,
      done: json['done'] as bool? ?? false,
    );
  }
}
