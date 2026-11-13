/// Icons named BY THE CONTRACT (header buttons, bottom bar).
///
/// The payload sends a semantic name (`cart`), never a library name
/// (`shoppingCart`): the contract stays the same if the icon library changes.
/// The web keeps the same table with lucide-react.
///
/// Icons that are just part of a section's look (a close "x", an arrow) are
/// used from the icon library directly by that section.
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final _contractIcons = <String, IconData>{
  'user': LucideIcons.user,
  'settings': LucideIcons.slidersHorizontal,
  'cart': LucideIcons.shoppingCart,
  'gift': LucideIcons.gift,
  'map_pin': LucideIcons.mapPin,
  'warning': LucideIcons.triangleAlert,
  'bell': LucideIcons.bell,
};

/// `null` for a name this client does not know: each section decides how to degrade.
IconData? contractIcon(String? name) => _contractIcons[name];
