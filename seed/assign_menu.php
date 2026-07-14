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

// Detectar el theme activo
$theme = wp_get_theme()->get_stylesheet();
echo "Active theme: $theme\n";

// Listar menu locations registradas por el theme
$locations = get_registered_nav_menus();
echo "Registered locations: " . json_encode($locations) . "\n";

// Asignar a TODAS las locations del theme (news-portal generalmente usa 'primary')
$loc_array = array();
foreach (array_keys($locations) as $loc) {
    $loc_array[$loc] = $menu_id;
}

// 1. theme_mods_<theme>
$mods = get_option("theme_mods_$theme");
if (!is_array($mods)) $mods = array();
$mods['nav_menu_locations'] = $loc_array;
update_option("theme_mods_$theme", $mods);

// 2. nav_menu_locations global
update_option('nav_menu_locations', $loc_array);

echo "Assigned menu $menu_id to: " . json_encode($loc_array) . "\n";

$items = wp_get_nav_menu_items($menu_id);
echo "Menu items: " . count($items) . "\n";
foreach ($items as $item) {
    echo "  - ID=" . $item->ID . " | " . $item->title . " -> " . $item->url . "\n";
}
