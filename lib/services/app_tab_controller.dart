import 'package:flutter/foundation.dart';

/// Shared tab index for [RootScreen]'s bottom navigation (0 = plants list,
/// 1 = camera), so screens pushed on top of it (e.g. the confirm-plant flow)
/// can switch back to the plants list without knowing about the widget tree.
class AppTabController {
  AppTabController._();
  static final AppTabController instance = AppTabController._();

  final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  void showHomeTab() => tabIndex.value = 0;
}
