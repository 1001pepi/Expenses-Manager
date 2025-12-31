import 'package:flutter/material.dart';

class IconCatalogScreen extends StatefulWidget {
  const IconCatalogScreen({super.key});

  @override
  State<IconCatalogScreen> createState() => _IconCatalogScreenState();
}

class _IconCatalogScreenState extends State<IconCatalogScreen> {
  IconData? _selectedIcon;

  static const Map<String, List<IconData>> _iconGroups = {
    'Finances': [
      Icons.savings_outlined,
      Icons.account_balance_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.attach_money_outlined,
      Icons.credit_card_outlined,
      Icons.currency_exchange_outlined,
      Icons.payments_outlined,
      Icons.receipt_long_outlined,
      Icons.money_outlined,
      Icons.paid_outlined,
      Icons.price_check_outlined,
      Icons.wallet_outlined,
    ],
    'Transportation': [
      Icons.directions_car_outlined,
      Icons.directions_bike_outlined,
      Icons.directions_bus_outlined,
      Icons.directions_boat_outlined,
      Icons.flight_outlined,
      Icons.train_outlined,
      Icons.subway_outlined,
      Icons.local_taxi_outlined,
      Icons.two_wheeler_outlined,
      Icons.electric_scooter_outlined,
      Icons.electric_car_outlined,
      Icons.motorcycle_outlined,
      Icons.local_shipping_outlined,
      Icons.railway_alert_outlined,
    ],
    'Shopping': [
      Icons.shopping_cart_outlined,
      Icons.shopping_bag_outlined,
      Icons.local_grocery_store_outlined,
      Icons.local_mall_outlined,
      Icons.store_outlined,
      Icons.storefront_outlined,
      Icons.local_offer_outlined,
      Icons.card_giftcard_outlined,
      Icons.redeem_outlined,
      Icons.loyalty_outlined,
      Icons.checkroom_outlined,
    ],
    'Food & Drink': [
      Icons.restaurant_outlined,
      Icons.local_cafe_outlined,
      Icons.local_pizza_outlined,
      Icons.local_bar_outlined,
      Icons.local_dining_outlined,
      Icons.fastfood_outlined,
      Icons.lunch_dining_outlined,
      Icons.dinner_dining_outlined,
      Icons.breakfast_dining_outlined,
      Icons.restaurant_menu_outlined,
      Icons.wine_bar_outlined,
      Icons.liquor_outlined,
      Icons.coffee_outlined,
      Icons.cake_outlined,
      Icons.icecream_outlined,
      Icons.ramen_dining_outlined,
      Icons.tapas_outlined,
    ],
    'Home': [
      Icons.home_outlined,
      Icons.house_outlined,
      Icons.cottage_outlined,
      Icons.apartment_outlined,
      Icons.other_houses_outlined,
      Icons.kitchen_outlined,
      Icons.bed_outlined,
      Icons.chair_outlined,
      Icons.weekend_outlined,
      Icons.lightbulb_outlined,
      Icons.light_outlined,
      Icons.heat_pump_outlined,
      Icons.water_drop_outlined,
      Icons.local_laundry_service_outlined,
      Icons.cleaning_services_outlined,
      Icons.home_repair_service_outlined,
      Icons.plumbing_outlined,
      Icons.electrical_services_outlined,
    ],
    'Health': [
      Icons.health_and_safety_outlined,
      Icons.local_hospital_outlined,
      Icons.medical_services_outlined,
      Icons.medication_outlined,
      Icons.vaccines_outlined,
      Icons.local_pharmacy_outlined,
      Icons.healing_outlined,
      Icons.monitor_heart_outlined,
      Icons.psychology_outlined,
      Icons.emergency_outlined,
      Icons.accessible_outlined,
      Icons.hearing_outlined,
      Icons.visibility_outlined,
    ],
    'Beauty': [
      Icons.face_outlined,
      Icons.spa_outlined,
      Icons.self_improvement_outlined,
      Icons.content_cut_outlined,
      Icons.brush_outlined,
      Icons.palette_outlined,
      Icons.local_florist_outlined,
      Icons.sanitizer_outlined,
      Icons.soap_outlined,
    ],
    'Entertainment': [
      Icons.sports_esports_outlined,
      Icons.local_movies_outlined,
      Icons.theaters_outlined,
      Icons.movie_outlined,
      Icons.music_note_outlined,
      Icons.headphones_outlined,
      Icons.mic_outlined,
      Icons.videogame_asset_outlined,
      Icons.casino_outlined,
      Icons.celebration_outlined,
      Icons.party_mode_outlined,
      Icons.nightlife_outlined,
      Icons.festival_outlined,
      Icons.attractions_outlined,
    ],
    'Account': [
      Icons.work_outline,
      Icons.business_outlined,
      Icons.badge_outlined,
      Icons.person_outlined,
      Icons.person_pin_outlined,
      Icons.account_circle_outlined,
      Icons.settings_outlined,
      Icons.admin_panel_settings_outlined,
      Icons.manage_accounts_outlined,
    ],
    'Workout': [
      Icons.fitness_center_outlined,
      Icons.sports_soccer_outlined,
      Icons.sports_basketball_outlined,
      Icons.sports_tennis_outlined,
      Icons.sports_baseball_outlined,
      Icons.sports_football_outlined,
      Icons.sports_volleyball_outlined,
      Icons.sports_golf_outlined,
      Icons.sports_hockey_outlined,
      Icons.sports_mma_outlined,
      Icons.sports_martial_arts_outlined,
      Icons.pool_outlined,
      Icons.hiking_outlined,
      Icons.downhill_skiing_outlined,
      Icons.snowboarding_outlined,
      Icons.skateboarding_outlined,
      Icons.surfing_outlined,
      Icons.kayaking_outlined,
      Icons.sledding_outlined,
      Icons.paragliding_outlined,
    ],
    'Relaxation': [
      Icons.spa_outlined,
      Icons.hot_tub_outlined,
      Icons.beach_access_outlined,
      Icons.pool_outlined,
      Icons.airline_seat_flat_outlined,
      Icons.weekend_outlined,
      Icons.self_improvement_outlined,
      Icons.nights_stay_outlined,
      Icons.bedtime_outlined,
      Icons.hotel_outlined,
    ],
    'Education': [
      Icons.school_outlined,
      Icons.local_library_outlined,
      Icons.book_outlined,
      Icons.menu_book_outlined,
      Icons.auto_stories_outlined,
      Icons.class_outlined,
      Icons.history_edu_outlined,
      Icons.science_outlined,
      Icons.calculate_outlined,
      Icons.biotech_outlined,
      Icons.engineering_outlined,
      Icons.architecture_outlined,
    ],
    'Family/Children': [
      Icons.family_restroom_outlined,
      Icons.child_care_outlined,
      Icons.child_friendly_outlined,
      Icons.toys_outlined,
      Icons.stroller_outlined,
      Icons.baby_changing_station_outlined,
      Icons.crib_outlined,
      Icons.gamepad_outlined,
      Icons.pets_outlined,
      Icons.park_outlined,
    ],
    'Farm': [
      Icons.agriculture_outlined,
      Icons.pets_outlined,
      Icons.grass_outlined,
      Icons.eco_outlined,
      Icons.yard_outlined,
      Icons.forest_outlined,
      Icons.nature_outlined,
      Icons.nature_people_outlined,
      Icons.local_florist_outlined,
    ],
    'Other': [
      Icons.category_outlined,
      Icons.more_horiz_outlined,
      Icons.devices_outlined,
      Icons.phone_iphone_outlined,
      Icons.computer_outlined,
      Icons.laptop_outlined,
      Icons.tablet_outlined,
      Icons.watch_outlined,
      Icons.camera_alt_outlined,
      Icons.photo_camera_outlined,
      Icons.print_outlined,
      Icons.map_outlined,
      Icons.place_outlined,
      Icons.explore_outlined,
      Icons.language_outlined,
      Icons.public_outlined,
      Icons.travel_explore_outlined,
      Icons.luggage_outlined,
      Icons.backpack_outlined,
      Icons.event_outlined,
      Icons.calendar_month_outlined,
      Icons.schedule_outlined,
      Icons.alarm_outlined,
      Icons.lock_outlined,
      Icons.key_outlined,
      Icons.vpn_key_outlined,
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Icon Catalog'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _iconGroups.length,
        cacheExtent: 500,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        itemBuilder: (context, groupIndex) {
          final groupName = _iconGroups.keys.elementAt(groupIndex);
          final icons = _iconGroups[groupName]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (groupIndex > 0) const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 22,
                  mainAxisSpacing: 22,
                ),
                itemCount: icons.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemBuilder: (context, index) {
                  final iconData = icons[index];
                  final isSelected = _selectedIcon == iconData;
                  return RepaintBoundary(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIcon = iconData;
                        });
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.12)
                              : Theme.of(context).colorScheme.surfaceVariant,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            iconData,
                            size: 35,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: Duration.zero,
        child: _selectedIcon != null
            ? SizedBox(
                width: 200,
                child: FloatingActionButton.extended(
                  onPressed: () => Navigator.pop(context, _selectedIcon),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  label: const Text(
                    'Select',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
