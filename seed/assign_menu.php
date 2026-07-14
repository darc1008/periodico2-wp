<?php
/**
 * periodico2 - One-shot menu assignment
 * Run via: CULTURINFO_MENU_ID=NN wp eval-file /seed/assign_menu.php
 */
$menu_id = (int) getenv('CULTURINFO_MENU_ID');
if (!$menu_id) {
    echo "ERROR: CULTURINFO_MENU_ID not set\n";
    return;
}

$mods = get_option('theme_mods_flavor');
if (!is_array($mods)) $mods = array();
$mods['nav_menu_locations'] = array('primary' => $menu_id);
update_option('theme_mods_flavor', $mods);
update_option('nav_menu_locations', array('primary' => $menu_id));

echo "theme_mods_flavor.nav_menu_locations = " . json_encode($mods['nav_menu_locations']) . "\n";
echo "nav_menu_locations = " . json_encode(get_option('nav_menu_locations')) . "\n";

$items = wp_get_nav_menu_items($menu_id);
echo "Menu items: " . count($items) . "\n";
foreach ($items as $item) {
    echo "  - ID=" . $item->ID . " | " . $item->title . " -> " . $item->url . "\n";
}
