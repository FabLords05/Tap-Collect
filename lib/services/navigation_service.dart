import 'package:flutter/foundation.dart';

/// Simple navigation notifier for switching the main bottom navigation index
class NavigationService {
  static final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

  static void goTo(int index) => currentIndex.value = index;
}
