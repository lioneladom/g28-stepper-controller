import 'package:flutter/material.dart';

class AppTabProvider extends ChangeNotifier {
  int _currentTab = 0;

  int get currentTab => _currentTab;

  void setTab(int index) {
    if (_currentTab != index) {
      _currentTab = index;
      notifyListeners();
    }
  }

  void navigateToScan() => setTab(0);
  void navigateToControl() => setTab(1);
  void navigateToSettings() => setTab(2);
}
