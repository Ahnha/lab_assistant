import 'package:flutter/material.dart';
import '../../../domain/procedure_step.dart';
import '../../../domain/step_status.dart';
import '../../../utils/decimal_input_formatter.dart';
import '../../../ui/widgets/ss_card.dart';
import '../../../ui/spacing.dart';

class InputNumberStepWidget extends StatefulWidget {
  final ProcedureStep step;
  final ValueChanged<ProcedureStep> onStepUpdated;
  final VoidCallback? onNavigateToIngredients;

  const InputNumberStepWidget({
    super.key,
    required this.step,
    required this.onStepUpdated,
    this.onNavigateToIngredients,
  });

  @override
  State<InputNumberStepWidget> createState() => _InputNumberStepWidgetState();
}

class _InputNumberStepWidgetState extends State<InputNumberStepWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final initialValue = widget.step.value;
    final initialText = initialValue != null
        ? (initialValue is double
              ? initialValue.toStringAsFixed(2)
              : initialValue.toString())
        : '';
    _controller = TextEditingController(text: initialText);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(InputNumberStepWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the value changed externally and field is not focused
    if (oldWidget.step.value != widget.step.value && !_focusNode.hasFocus) {
      final newValue = widget.step.value;
      final newText = newValue != null
          ? (newValue is double
                ? newValue.toStringAsFixed(2)
                : newValue.toString())
          : '';
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // When focus is lost, format the value to 2 decimals
    if (!_focusNode.hasFocus) {
      final text = _controller.text;
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null) {
          final formatted = value.toStringAsFixed(2);
          _controller.text = formatted;
          // Collapse cursor to end after formatting
          _controller.selection = TextSelection.collapsed(
            offset: formatted.length,
          );
        }
      }
    }
  }

  void _onValueChanged(String value) {
    final numValue = num.tryParse(value);
    final updated = ProcedureStep(
      id: widget.step.id,
      kind: widget.step.kind,
      title: widget.step.title,
      description: widget.step.description,
      order: widget.step.order,
      status: numValue != null ? StepStatus.done : StepStatus.doing,
      timerSeconds: widget.step.timerSeconds,
      remainingSeconds: widget.step.remainingSeconds,
      timerState: widget.step.timerState,
      timerStartedAt: widget.step.timerStartedAt,
      unit: widget.step.unit,
      value: numValue,
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
            if (widget.step.description != null &&
                widget.step.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.step.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [DecimalInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Value',
                      border: const OutlineInputBorder(),
                      suffixText: widget.step.unit,
                      suffixIcon: widget.step.value != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _controller.clear();
                                _onValueChanged('');
                              },
                              tooltip: 'Clear',
                            )
                          : null,
                    ),
                    onChanged: _onValueChanged,
                    onEditingComplete: () {
                      // Format on editing complete
                      _onFocusChanged();
                      _focusNode.unfocus();
                    },
                    onSubmitted: (_) {
                      // Format on submit
                      _onFocusChanged();
                    },
                  ),
                ),
              ],
            ),
            if (widget.step.value != null) ...[
              const SizedBox(height: 8),
              Text(
                'Current: ${widget.step.value} ${widget.step.unit ?? ''}',
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
