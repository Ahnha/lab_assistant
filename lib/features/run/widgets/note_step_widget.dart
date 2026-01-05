import 'package:flutter/material.dart';
import '../../../domain/procedure_step.dart';
import '../../../domain/step_status.dart';
import '../../../ui/widgets/ss_card.dart';
import '../../../ui/spacing.dart';

class NoteStepWidget extends StatefulWidget {
  final ProcedureStep step;
  final ValueChanged<ProcedureStep> onStepUpdated;
  final VoidCallback? onNavigateToIngredients;

  const NoteStepWidget({
    super.key,
    required this.step,
    required this.onStepUpdated,
    this.onNavigateToIngredients,
  });

  @override
  State<NoteStepWidget> createState() => _NoteStepWidgetState();
}

class _NoteStepWidgetState extends State<NoteStepWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // For note steps, we can store the note in the description or use a separate field
    // For simplicity, we'll use description to store the note content
    _controller = TextEditingController(text: widget.step.description ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveNote() {
    final noteText = _controller.text.trim();
    final updated = ProcedureStep(
      id: widget.step.id,
      kind: widget.step.kind,
      title: widget.step.title,
      description: noteText.isEmpty ? null : noteText,
      order: widget.step.order,
      status: noteText.isNotEmpty ? StepStatus.done : StepStatus.todo,
      timerSeconds: widget.step.timerSeconds,
      remainingSeconds: widget.step.remainingSeconds,
      timerState: widget.step.timerState,
      timerStartedAt: widget.step.timerStartedAt,
      ingredientSectionId: widget.step.ingredientSectionId,
      ingredientSectionLabel: widget.step.ingredientSectionLabel,
    );
    widget.onStepUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SsCard(
      child: Padding(
        padding: LabSpacing.cardInsets(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.step.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (widget.step.ingredientSectionId != null &&
                widget.onNavigateToIngredients != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [_buildIngredientChip(context)],
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _controller,
              maxLines: null,
              minLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter your notes here...',
                border: const OutlineInputBorder(),
                suffixIcon:
                    widget.step.description != null &&
                        widget.step.description!.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _saveNote();
                        },
                        tooltip: 'Clear note',
                      )
                    : null,
              ),
              onChanged: (_) => _saveNote(),
            ),
            if (widget.step.description != null &&
                widget.step.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Saved',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientChip(BuildContext context) {
    final label = widget.step.ingredientSectionLabel ?? 'Ingredients';
    return InkWell(
      onTap: widget.onNavigateToIngredients,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Ingredients → $label',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.arrow_forward,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
