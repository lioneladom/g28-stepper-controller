import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class TerminalLogger extends StatefulWidget {
  final List<String> logs;

  const TerminalLogger({super.key, required this.logs});

  @override
  State<TerminalLogger> createState() => _TerminalLoggerState();
}

class _TerminalLoggerState extends State<TerminalLogger> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant TerminalLogger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF090A0B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF23272E)),
      ),
      child: widget.logs.isEmpty
          ? Center(
              child: Text(
                "NO LOG DATA RECORDED",
                style: AppTheme.monoSubheader(fontSize: 10, color: const Color(0xFF4E5460)),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: widget.logs.length,
              itemBuilder: (context, index) {
                final line = widget.logs[index];
                final isError = line.contains("Error") || line.contains("EMERGENCY");
                final isWarning = line.contains("GATT") || line.contains("Write");

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    line,
                    style: AppTheme.monoSubheader(
                      fontSize: 11,
                      color: isError
                          ? AppTheme.brightDangerRed
                          : isWarning
                              ? AppTheme.primaryAccent
                              : const Color(0xFF8B92A0),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
