enum Flavor {
  combined,
  reddit,
  digg,
  lemmy,
}

class F {
  static late final Flavor appFlavor;

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.combined:
        return 'Lurk';
      case Flavor.reddit:
        return 'Lurk Reddit';
      case Flavor.digg:
        return 'Lurk Digg';
      case Flavor.lemmy:
        return 'Lurk Lemmy';
    }
  }

}
