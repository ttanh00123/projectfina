// lib/utils/material_icons_map.dart

import 'package:flutter/material.dart';

const Map<String, IconData> kMaterialIconsMap = {
  'restaurant':          Icons.restaurant,
  'directions_car':      Icons.directions_car,
  'phone_android':       Icons.phone_android,
  'wifi':                Icons.wifi,
  'local_gas_station':   Icons.local_gas_station,
  'shopping_basket':     Icons.shopping_basket,
  'checkroom':           Icons.checkroom,
  'face':                Icons.face,
  'movie':               Icons.movie,
  'flight':              Icons.flight,
  'family_restroom':     Icons.family_restroom,
  'celebration':         Icons.celebration,
  'local_hospital':      Icons.local_hospital,
  'medication':          Icons.medication,
  'fitness_center':      Icons.fitness_center,
  'savings':             Icons.savings,
  'build':               Icons.build,
  'car_crash':           Icons.car_crash,
  'gavel':               Icons.gavel,
  'home':                Icons.home,
  'bolt':                Icons.bolt,
  'water_drop':          Icons.water_drop,
  'school':              Icons.school,
  'security':            Icons.security,
  'credit_score':        Icons.credit_score,
  'payments':            Icons.payments,
  'card_giftcard':       Icons.card_giftcard,
  'volunteer_activism':  Icons.volunteer_activism,
  'storefront':          Icons.storefront,
  'trending_up':         Icons.trending_up,
  'auto_awesome':        Icons.auto_awesome,
  'redeem':              Icons.redeem,
  'add_circle_outline':  Icons.add_circle_outline,
};

IconData iconFromKey(String key) =>
    kMaterialIconsMap[key] ?? Icons.category_outlined;