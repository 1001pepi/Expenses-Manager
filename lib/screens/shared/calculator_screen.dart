import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _operation = '';
  double _firstOperand = 0;
  bool _shouldResetDisplay = false;
  bool _showResult = false;

  void _onNumberPressed(String number) {
    setState(() {
      if (_shouldResetDisplay || _display == '0') {
        _display = number;
        _shouldResetDisplay = false;
      } else {
        // Handle '00' button
        if (number == '00') {
          _display += '00';
        } else {
          _display += number;
        }
      }
      _showResult = false;
    });
  }

  void _onDecimalPressed() {
    setState(() {
      if (_shouldResetDisplay) {
        _display = '0.';
        _shouldResetDisplay = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
      _showResult = false;
    });
  }

  void _onOperationPressed(String operation) {
    setState(() {
      _firstOperand = double.tryParse(_display) ?? 0;
      _operation = operation;
      _shouldResetDisplay = true;
      _showResult = false;
    });
  }

  void _onEqualsPressed() {
    if (_showResult) {
      // If result is already shown, confirm and return
      Future.microtask(() {
        if (mounted) {
          Navigator.pop(context, _display);
        }
      });
    } else {
      // Calculate and show result
      setState(() {
        double secondOperand = double.tryParse(_display) ?? 0;
        double result = 0;

        switch (_operation) {
          case '+':
            result = _firstOperand + secondOperand;
            break;
          case '-':
            result = _firstOperand - secondOperand;
            break;
          case '×':
            result = _firstOperand * secondOperand;
            break;
          case '÷':
            result = secondOperand != 0 ? _firstOperand / secondOperand : 0;
            break;
          default:
            result = secondOperand;
        }

        // Format result to remove unnecessary decimals
        if (result == result.toInt()) {
          _display = result.toInt().toString();
        } else {
          _display = result.toStringAsFixed(2);
        }

        _operation = '';
        _shouldResetDisplay = true;
        _showResult = true;
      });
    }
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _operation = '';
      _firstOperand = 0;
      _shouldResetDisplay = false;
      _showResult = false;
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
      _showResult = false;
    });
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    Widget? icon,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor:
                  textColor ?? Theme.of(context).colorScheme.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.zero,
              elevation: 1,
              shadowColor: Colors.black.withOpacity(0.1),
            ),
            child:
                icon ??
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculator'), centerTitle: false),
      body: Column(
        children: [
          // Display
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_operation.isNotEmpty)
                    Text(
                      '$_firstOperand $_operation',
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _display,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),
          // Buttons
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Column(
                children: [
                  // Row 1: C, ⌫, %, ÷
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(
                          text: 'C',
                          onPressed: _onClearPressed,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.errorContainer,
                          textColor: Theme.of(
                            context,
                          ).colorScheme.onErrorContainer,
                        ),
                        _buildButton(
                          text: '⌫',
                          onPressed: _onBackspacePressed,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          textColor: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                        _buildButton(
                          text: '%',
                          onPressed: () {},
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainer,
                        ),
                        _buildButton(
                          text: '÷',
                          onPressed: () => _onOperationPressed('÷'),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          textColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                  // Row 2: 7, 8, 9, ×
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(
                          text: '7',
                          onPressed: () => _onNumberPressed('7'),
                        ),
                        _buildButton(
                          text: '8',
                          onPressed: () => _onNumberPressed('8'),
                        ),
                        _buildButton(
                          text: '9',
                          onPressed: () => _onNumberPressed('9'),
                        ),
                        _buildButton(
                          text: '×',
                          onPressed: () => _onOperationPressed('×'),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          textColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                  // Row 3: 4, 5, 6, -
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(
                          text: '4',
                          onPressed: () => _onNumberPressed('4'),
                        ),
                        _buildButton(
                          text: '5',
                          onPressed: () => _onNumberPressed('5'),
                        ),
                        _buildButton(
                          text: '6',
                          onPressed: () => _onNumberPressed('6'),
                        ),
                        _buildButton(
                          text: '-',
                          onPressed: () => _onOperationPressed('-'),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          textColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                  // Row 4: 1, 2, 3, +
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(
                          text: '1',
                          onPressed: () => _onNumberPressed('1'),
                        ),
                        _buildButton(
                          text: '2',
                          onPressed: () => _onNumberPressed('2'),
                        ),
                        _buildButton(
                          text: '3',
                          onPressed: () => _onNumberPressed('3'),
                        ),
                        _buildButton(
                          text: '+',
                          onPressed: () => _onOperationPressed('+'),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          textColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                  // Row 5: 0, 00, ., =
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(
                          text: '0',
                          onPressed: () => _onNumberPressed('0'),
                        ),
                        _buildButton(
                          text: '00',
                          onPressed: () => _onNumberPressed('00'),
                        ),
                        _buildButton(text: '.', onPressed: _onDecimalPressed),
                        _buildButton(
                          text: _showResult ? '✓' : '=',
                          onPressed: _onEqualsPressed,
                          backgroundColor: _showResult
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.primary,
                          textColor: _showResult
                              ? Theme.of(context).colorScheme.onTertiary
                              : Theme.of(context).colorScheme.onPrimary,
                          icon: _showResult
                              ? Icon(
                                  Icons.check,
                                  size: 24,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onTertiary,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
