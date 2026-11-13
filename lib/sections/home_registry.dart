/// What the HOME can render: its sections, picked from the shared catalog
/// (lib/sections). Each screen has its own registry (plp_registry.dart,
/// checkout_registry.dart...), so a screen only lists what it uses.
///
/// Adding a section to the home = one line here. A type that is not listed is
/// skipped and reported as `unknown_type`.
library;

import 'package:sdui/sdui.dart';

import 'bottom_bar.dart';
import 'header_default.dart';
import 'header_greeting.dart';
import 'hero_carousel.dart';
import 'product_list.dart';
import 'promo_banner.dart';

final homeRegistry = createSectionRegistry([
  // header slot
  headerDefault,
  headerGreeting,
  // body
  heroCarousel,
  productList,
  promoBanner,
  // bottomBar slot
  bottomBar,
]);
