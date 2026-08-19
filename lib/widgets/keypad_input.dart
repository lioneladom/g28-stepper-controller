import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class KeypadInput extends StatefulWidget {
  final ValueChanged<int> onTargetSubmitted;
  final ValueChanged<int> onJogStep;

  const KeypadInput({
    super.key,
    required this.onTargetSubmitted,
    required this.onJogStep,
  });

  @override
  State<KeypadInput> createState() => _KeypadInputState();
}

class _KeypadInputState extends State<KeypadInput> {
  String _inputBuffer = "120";

  void _onKeyPress(String val) {
    setState(() {
      if (val == "C") {
        _inputBuffer = "0";
      } else if (val == "GO") {
        final parsed = int.tryParse(_inputBuffer) ?? 0;
        widget.onTargetSubmitted(parsed);
      } else {
        if (_inputBuffer == "0") {
          _inputBuffer = val;
        } else if (_inputBuffer.length < 5) {
          _inputBuffer += val;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Input display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: const Color(0xFF1F242B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Text(
            "$_inputBuffer°",
            style: AppTheme.monoValue(fontSize: 28, color: AppTheme.primaryAccent),
          ),
        ),
        const SizedBox(height: 12),

        // Numeric Keypad 3x4 Grid
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [
              _buildRow(['7', '8', '9']),
              const Divider(height: 1, color: AppTheme.cardBorder),
              _buildRow(['4', '5', '6']),
              const Divider(height: 1, color: AppTheme.cardBorder),
              _buildRow(['1', '2', '3']),
              const Divider(height: 1, color: AppTheme.cardBorder),
              _buildRow(['C', '0', 'GO']),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Jog Step Buttons (+1, +10, -1, -10)
        Text(
          "JOG STEPS",
          style: AppTheme.monoSubheader(fontSize: 11, color: const Color(0xFF6C727F)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildJogBtn("+1", 1)),
            const SizedBox(width: 8),
            Expanded(child: _buildJogBtn("+10", 10)),
            const SizedBox(width: 8),
            Expanded(child: _buildJogBtn("-1", -1)),
            const SizedBox(width: 8),
            Expanded(child: _buildJogBtn("-10", -10)),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        final isGo = key == "GO";
        final isClear = key == "C";
        return Expanded(
          child: InkWell(
            onTap: () => _onKeyPress(key),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isGo
                    ? AppTheme.primaryAccent
                    : isClear
                        ? const Color(0xFF23272E)
                        : Colors.transparent,
                border: Border.all(color: AppTheme.cardBorder, width: 0.5),
              ),
              child: Text(
                key,
                style: AppTheme.monoHeader(
                  fontSize: 18,
                  color: isGo ? Colors.black : (isClear ? AppTheme.brightDangerRed : Colors.white),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJogBtn(String label, int step) {
    return Material(
      color: AppTheme.cardBgElevated,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => widget.onJogStep(step),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.cardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTheme.monoHeader(fontSize: 16, color: AppTheme.primaryAccent),
              ),
              Text(
                "DEGREES",
                style: AppTheme.monoSubheader(fontSize: 8, color: const Color(0xFF6C727F)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
