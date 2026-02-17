import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/services/settings.dart';

import 'app.dart';
import 'core/flavors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  F.appFlavor = Flavor.values.firstWhere((element) => element.name == appFlavor);
  Settings.onSessionsInvalidated = (platform) => platform.destroyAllSessions();
  runApp(const App());
}
