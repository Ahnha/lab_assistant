import 'package:flutter/material.dart';
import '../../domain/lab_run.dart';
import '../../domain/procedure_step.dart';
import '../../domain/step_kind.dart';
import '../../domain/step_status.dart';
import '../run/run_detail_screen.dart';
import 'components/workspace_header.dart';
import 'components/next_action_card.dart';

/// Workspace widget for displaying and interacting with a run.
/// Used in both 2-pane desktop layout and as a dedicated page on mobile.
/// This wraps RunDetailScreen with a premium header and next action card.
class RunWorkspace extends StatefulWidget {
  final LabRun run;
  final ValueChanged<LabRun>? onRunUpdated;
  final VoidCallback? onRunDeleted;
  final double? spacingScale;

  const RunWorkspace({
    super.key,
    required this.run,
    this.onRunUpdated,
    this.onRunDeleted,
    this.spacingScale,
  });

  @override
  State<RunWorkspace> createState() => _RunWorkspaceState();
}

class _RunWorkspaceState extends State<RunWorkspace> {
  String? _focusStepId;

  ProcedureStep? _getNextIncompleteStep() {
    for (final step in widget.run.steps) {
      if (step.kind != StepKind.section &&
          step.status != StepStatus.done &&
          step.status != StepStatus.skipped) {
        return step;
      }
    }
    return null;
  }

  void _handleContinue() {
    final nextStep = _getNextIncompleteStep();
    if (nextStep != null) {
      setState(() {
        _focusStepId = nextStep.id;
      });
      // Rebuild with focus - RunDetailScreen will scroll to it
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sticky workspace header
        WorkspaceHeader(
          run: widget.run,
          onRunUpdated: widget.onRunUpdated,
          onRunDeleted: widget.onRunDeleted,
          spacingScale: widget.spacingScale,
        ),
        // Next action card
        NextActionCard(
          run: widget.run,
          onContinue: _handleContinue,
          spacingScale: widget.spacingScale,
        ),
        // Run detail content (without AppBar)
        Expanded(
          child: RunDetailScreen(
            key: ValueKey('${widget.run.id}_$_focusStepId'),
            run: widget.run,
            onRunUpdated: widget.onRunUpdated,
            onRunDeleted: widget.onRunDeleted,
            isEmbedded: true,
            hideAppBar: true,
            initialStepId: _focusStepId,
          ),
        ),
      ],
    );
  }
}
