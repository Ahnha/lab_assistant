import 'package:flutter/material.dart';
import '../../../domain/lab_run.dart';
import '../../../domain/recipe_kind.dart';
import '../../../domain/formula_phase.dart';
import '../../../domain/formula_item.dart';
import '../../../domain/formula.dart';
import '../../../domain/lab_run_scaler.dart';
import '../../../domain/ingredient_section_helper.dart';
import '../../../utils/decimal_input_formatter.dart';
import '../../../app/ui_tokens.dart';
import '../../../app/widgets/app_card.dart';

class IngredientsView extends StatefulWidget {
  final LabRun run;
  final Function(LabRun)? onRunUpdated;
  final ScrollController? scrollController;
  final Function(String)? onIngredientCheckToggled;

  const IngredientsView({
    super.key,
    required this.run,
    this.onRunUpdated,
    this.scrollController,
    this.onIngredientCheckToggled,
  });

  @override
  State<IngredientsView> createState() => IngredientsViewState();
}

class IngredientsViewState extends State<IngredientsView> {
  late LabRun _run;
  final TextEditingController _batchSizeController = TextEditingController();
  final FocusNode _batchSizeFocusNode = FocusNode();
  late ScrollController _scrollController;

  // GlobalKeys for section anchors
  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  void initState() {
    super.initState();
    _run = widget.run;
    _updateBatchSizeController();
    _scrollController = widget.scrollController ?? ScrollController();
    _initializeSectionKeys();
  }

  void _initializeSectionKeys() {
    // For cream: create keys for each phase
    if (_run.recipe.kind == RecipeKind.cream &&
        _run.formula?.isCreamStyle == true) {
      final phases = _run.formula!.phases!;
      for (final phase in phases) {
        final phaseLetter = String.fromCharCode(65 + (phase.order - 1));
        final keyId = 'phase:p$phaseLetter';
        _sectionKeys[keyId] = GlobalKey();
      }
    } else if (_run.formula?.isSoapStyle == true) {
      // For soap: create keys for Oils and Lye/Water
      _sectionKeys['soap:oils'] = GlobalKey();
      _sectionKeys['soap:lyeWater'] = GlobalKey();
    }
  }

  @override
  void didUpdateWidget(IngredientsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.run != widget.run) {
      _run = widget.run;
      _updateBatchSizeController();
    }
  }

  void _updateBatchSizeController() {
    // Only update if field is not focused to avoid cursor jumping
    if (_batchSizeFocusNode.hasFocus) {
      return;
    }

    final formula = _run.formula;
    if (formula == null) {
      _batchSizeController.text = '';
      return;
    }

    // For soap: show oilsTotalGrams, for cream: show batchSizeGrams
    if (formula.isSoapStyle && formula.oilsTotalGrams != null) {
      _batchSizeController.text = formula.oilsTotalGrams!.toStringAsFixed(2);
    } else if (formula.isCreamStyle && formula.batchSizeGrams != null) {
      _batchSizeController.text = formula.batchSizeGrams!.toStringAsFixed(2);
    } else {
      _batchSizeController.text = '';
    }
  }

  void _onBatchSizeFocusChanged() {
    // When focus is lost, format the value to 2 decimals
    if (!_batchSizeFocusNode.hasFocus) {
      final text = _batchSizeController.text;
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null) {
          final formatted = value.toStringAsFixed(2);
          _batchSizeController.text = formatted;
          // Collapse cursor to end after formatting
          _batchSizeController.selection = TextSelection.collapsed(
            offset: formatted.length,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _batchSizeFocusNode.removeListener(_onBatchSizeFocusChanged);
    _batchSizeFocusNode.dispose();
    _batchSizeController.dispose();
    // Only dispose if we created the controller ourselves
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void scrollToSection(String sectionId) {
    final key = _sectionKeys[sectionId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1, // Scroll to show section near top
      );
    }
  }

  bool _hasPercentages() {
    return _run.formula?.hasPercentagesForScaling ?? false;
  }

  void _onBatchSizeChanged(String value) {
    final batchSize = double.tryParse(value);
    if (batchSize == null || batchSize <= 0) {
      return;
    }

    if (_run.formula == null) {
      return;
    }

    final formula = _run.formula!;
    LabRun updatedRun;

    if (formula.isSoapStyle) {
      // For soap: scale oils based on new oilsTotalGrams
      updatedRun = scaleSoapOils(_run, batchSize);
    } else if (formula.isCreamStyle) {
      // For cream: scale phase items based on new batchSizeGrams
      updatedRun = scalePhaseItems(_run, batchSize);
    } else {
      return;
    }

    setState(() {
      _run = updatedRun;
    });

    widget.onRunUpdated?.call(updatedRun);
  }

  @override
  Widget build(BuildContext context) {
    if (_run.formula == null) {
      return Center(
        child: Padding(
          padding: UITokens.paddingXXXL,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.science_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: UITokens.spacingL),
              Text(
                'No formula available',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: UITokens.spacingS),
              Text(
                'Formula data not provided for this run',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final formula = _run.formula!;
    final hasPercentages = _hasPercentages();

    // Check if this is a cream recipe with phases
    if (_run.recipe.kind == RecipeKind.cream && formula.isCreamStyle) {
      return _buildCreamView(context, formula, hasPercentages);
    }

    // Otherwise, render soap-style formula
    return _buildSoapView(context, formula, hasPercentages);
  }

  Widget _buildCreamView(
    BuildContext context,
    Formula formula,
    bool hasPercentages,
  ) {
    final phases = formula.phases!;
    // Sort phases by order
    final sortedPhases = List<FormulaPhase>.from(phases)
      ..sort((a, b) => a.order.compareTo(b.order));

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBatchSizeInput(context, hasPercentages),
          const SizedBox(height: 24),
          ...sortedPhases.map((phase) {
            final phaseLetter = String.fromCharCode(65 + (phase.order - 1));
            final keyId = 'phase:p$phaseLetter';
            final sectionKey = _sectionKeys[keyId];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: PhaseSection(
                phase: phase,
                sectionKey: sectionKey,
                run: _run,
                onIngredientCheckToggled: widget.onIngredientCheckToggled,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSoapView(
    BuildContext context,
    Formula formula,
    bool hasPercentages,
  ) {
    if (!formula.isSoapStyle) {
      return Center(
        child: Padding(
          padding: UITokens.paddingXXXL,
          child: Text(
            'Invalid formula format',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBatchSizeInput(context, hasPercentages),
          const SizedBox(height: 24),
          Text('Oils', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            key: _sectionKeys['soap:oils'],
            child: Column(
              children: [
                ...formula.oils!.asMap().entries.map((entry) {
                  final oil = entry.value;
                  final index = entry.key;
                  final checkKey = IngredientSectionHelper.getSoapOilKey(
                    oil.id,
                    oil.name,
                    index,
                  );
                  final isChecked = _run.ingredientChecks[checkKey] ?? false;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UITokens.spacingL,
                      vertical: UITokens.spacingM,
                    ),
                    child: InkWell(
                      onTap: () => widget.onIngredientCheckToggled?.call(checkKey),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isChecked,
                            onChanged: (_) =>
                                widget.onIngredientCheckToggled?.call(checkKey),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              oil.name,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                decoration: isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isChecked
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6)
                                    : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (oil.percent != null)
                            SizedBox(
                              width: 56,
                              child: Text(
                                '${oil.percent!.toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          SizedBox(
                            width: 72,
                            child: Text(
                              '${oil.grams.toStringAsFixed(2)} g',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w500),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total Oils',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        width: 72,
                        child: Text(
                          '${formula.oilsTotalGrams?.toStringAsFixed(2) ?? "0.00"} g',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Lye & Water', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            key: _sectionKeys['soap:lyeWater'],
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formula.lye!.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 72,
                        child: Text(
                          '${formula.lye!.grams.toStringAsFixed(2)} g',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formula.water!.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 72,
                        child: Text(
                          '${formula.water!.grams.toStringAsFixed(2)} g',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (formula.superfatPercent != null) ...[
            const SizedBox(height: UITokens.spacingXXL),
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Superfat',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${formula.superfatPercent!.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBatchSizeInput(BuildContext context, bool hasPercentages) {
    final formula = _run.formula;
    final isSoap = formula?.isSoapStyle ?? false;
    final label = isSoap ? 'Total oils (g)' : 'Batch size (g)';

    // Calculate totals for validation
    double? computedTotal;
    double? targetTotal;
    String? totalLabel;
    double? difference;
    double? totalPercent;

    if (formula != null) {
      if (isSoap) {
        computedTotal = calculateSoapOilsTotal(formula);
        targetTotal = formula.oilsTotalGrams;
        totalLabel = 'Oils total';
        totalPercent = calculateSoapOilsTotalPercent(formula);
      } else if (formula.isCreamStyle) {
        computedTotal = calculateCreamItemsTotal(formula);
        targetTotal = formula.batchSizeGrams;
        totalLabel = 'Items with % total';
        totalPercent = calculateCreamItemsTotalPercent(formula);
      }

      if (computedTotal != null && targetTotal != null) {
        difference = computedTotal - targetTotal;
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (!hasPercentages)
                Padding(
                  padding: const EdgeInsets.only(left: UITokens.spacingS),
                  child: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: UITokens.spacingM),
          TextField(
            controller: _batchSizeController,
            focusNode: _batchSizeFocusNode,
            enabled: hasPercentages,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [DecimalInputFormatter()],
            decoration: InputDecoration(
              hintText: 'Enter ${label.toLowerCase()}',
              suffixText: 'g',
              helperText: hasPercentages
                  ? null
                  : 'Scaling requires percentages',
              helperStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onChanged: hasPercentages ? _onBatchSizeChanged : null,
            onEditingComplete: () {
              // Format on editing complete
              _onBatchSizeFocusChanged();
              _batchSizeFocusNode.unfocus();
            },
            onSubmitted: (_) {
              // Format on submit
              _onBatchSizeFocusChanged();
            },
          ),
          if (hasPercentages &&
              computedTotal != null &&
              totalLabel != null) ...[
            const SizedBox(height: UITokens.spacingM),
            Text(
              '$totalLabel: ${computedTotal.toStringAsFixed(2)} g (from ${isSoap ? "oils%" : "items%"})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (difference != null && difference.abs() > 0.05) ...[
              const SizedBox(height: UITokens.spacingXS),
              Builder(
                builder: (context) {
                  final diff = difference!;
                  if (totalPercent != null &&
                      totalPercent >= 99.9 &&
                      totalPercent <= 100.1) {
                    // Percent total is valid, difference is due to decimals
                    return Text(
                      'Difference: ${diff > 0 ? "+" : ""}${diff.toStringAsFixed(2)}g (due to decimals)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  } else if (totalPercent != null && targetTotal != null) {
                    // Percent total is outside valid range
                    final missingPercent = 100.0 - totalPercent;
                    final missingGrams = targetTotal * missingPercent / 100.0;
                    final isWarning = missingPercent.abs() > 1.0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Percent total: ${totalPercent.toStringAsFixed(1)}% (missing ${missingPercent.toStringAsFixed(1)}%)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isWarning
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: UITokens.spacingXS / 2),
                        Text(
                          'Missing grams: ${missingGrams.toStringAsFixed(2)} g',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isWarning
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
          if (isSoap && hasPercentages && formula?.lye != null) ...[
            const SizedBox(height: UITokens.spacingM),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: UITokens.spacingS),
                Expanded(
                  child: Text(
                    'Note: Lye/Water are not scaled automatically.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class PhaseSection extends StatelessWidget {
  final FormulaPhase phase;
  final GlobalKey? sectionKey;
  final LabRun run;
  final Function(String)? onIngredientCheckToggled;

  const PhaseSection({
    super.key,
    required this.phase,
    this.sectionKey,
    required this.run,
    this.onIngredientCheckToggled,
  });

  @override
  Widget build(BuildContext context) {
    // Get phase letter (A, B, C, etc.) from order
    final phaseLetter = String.fromCharCode(65 + (phase.order - 1)); // A=65
    // Use constructed phase ID format (pA, pB, etc.) to match section ID format
    final phaseId = 'p$phaseLetter';

    return Card(
      key: sectionKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: UITokens.paddingL,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Phase $phaseLetter — ${phase.name}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (phase.totalGrams != null)
                  Text(
                    '${phase.totalGrams} g',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...phase.items.asMap().entries.map((entry) {
            final item = entry.value;
            final index = entry.key;
            final checkKey = IngredientSectionHelper.getPhaseItemKey(
              phaseId,
              item.id,
              item.name,
              index,
            );
            final isChecked = run.ingredientChecks[checkKey] ?? false;
            return IngredientRow(
              item: item,
              isChecked: isChecked,
              onTap: onIngredientCheckToggled != null
                  ? () => onIngredientCheckToggled!(checkKey)
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

class IngredientRow extends StatelessWidget {
  final FormulaItem item;
  final bool isChecked;
  final VoidCallback? onTap;

  const IngredientRow({
    super.key,
    required this.item,
    this.isChecked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: UITokens.spacingL,
          vertical: UITokens.spacingM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (onTap != null) ...[
                  Checkbox(
                    value: isChecked,
                    onChanged: (_) => onTap?.call(),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      decoration: isChecked
                          ? TextDecoration.lineThrough
                          : null,
                      color: isChecked
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6)
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.percent != null)
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${item.percent!.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                SizedBox(
                  width: 72,
                  child: Text(
                    '${item.grams.toStringAsFixed(2)} g',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
