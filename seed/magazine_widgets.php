<?php
/**
 * Pobla los widget areas de la página Magazine de Editorial:
 *  - editorial_home_slider_area  (slider principal)
 *  - editorial_home_content_area (grids por categoría)
 *  - editorial_home_sidebar      (sidebar lateral)
 *
 * Editorial viene con sus propios widgets:
 *  - editorial_featured_slider  (1 slider con N posts)
 *  - editorial_block_layout     (grid categoría con título)
 *  - editorial_block_list       (lista vertical)
 *  - editorial_block_grid       (grid compacto)
 *  - editorial_block_column     (columnas)
 *  - editorial_posts_list       (lista simple)
 *  - editorial_ads_banner       (banner ad)
 */

// Resolver IDs de categorías
function p2_get_cat_id($slug) {
    $term = get_term_by('slug', $slug, 'category');
    return $term ? (int) $term->term_id : 0;
}

$cat_politica  = p2_get_cat_id('politica');
$cat_economia  = p2_get_cat_id('economia');
$cat_mundo     = p2_get_cat_id('mundo');
$cat_tecnologia= p2_get_cat_id('tecnologia');
$cat_deportes  = p2_get_cat_id('deportes');
$cat_cultura   = p2_get_cat_id('cultura');
$cat_opinion   = p2_get_cat_id('opinion');
$cat_estilo    = p2_get_cat_id('estilo');

echo "cat_ids: politica=$cat_politica economia=$cat_economia mundo=$cat_mundo tecno=$cat_tecnologia dep=$cat_deportes cultura=$cat_cultura opinion=$cat_opinion estilo=$cat_estilo\n";

/* ============================================================================
 * 1) SLIDER: editorial_featured_slider
 *    Crea 2 instancias: slider de 5 posts (Tecnología) + featured block 4 posts (Política)
 * ============================================================================ */
$slider_widgets = array();

// Featured slider: posts de Tecnologia
$slider_widgets[1] = array(
    'editorial_slider_category'    => $cat_tecnologia,
    'editorial_slide_count'        => 4,
    'editorial_featured_category'  => $cat_politica,
    'editorial_featured_count'     => 3,
);

/* ============================================================================
 * 2) CONTENT: editorial_block_layout (grid de posts por categoría)
 *    Una instancia por categoría principal
 * ============================================================================ */
$content_widgets = array();

// Economía
$content_widgets[2] = array(
    'editorial_block_title'        => 'Economía',
    'editorial_block_cat_id'       => $cat_economia,
    'editorial_block_posts_count'  => 5,
);
// Mundo
$content_widgets[3] = array(
    'editorial_block_title'        => 'Mundo',
    'editorial_block_cat_id'       => $cat_mundo,
    'editorial_block_posts_count'  => 5,
);
// Cultura
$content_widgets[4] = array(
    'editorial_block_title'        => 'Cultura',
    'editorial_block_cat_id'       => $cat_cultura,
    'editorial_block_posts_count'  => 4,
);
// Deportes
$content_widgets[5] = array(
    'editorial_block_title'        => 'Deportes',
    'editorial_block_cat_id'       => $cat_deportes,
    'editorial_block_posts_count'  => 4,
);
// Opinión
$content_widgets[6] = array(
    'editorial_block_title'        => 'Opinión',
    'editorial_block_cat_id'       => $cat_opinion,
    'editorial_block_posts_count'  => 4,
);

/* ============================================================================
 * 3) SIDEBAR: lista de últimas + categorías
 * ============================================================================ */
$sidebar_widgets = array();

// Posts recientes
$sidebar_widgets[7] = array(
    'title' => 'Últimas Noticias',
    'number'=> 8,
    'show_date' => 1,
);

// Categorías
$sidebar_widgets[8] = array(
    'title' => 'Categorías',
    'count' => 0,
    'hierarchical' => 0,
    'dropdown' => 0,
);

/* ============================================================================
 * ESCRITURA EN OPTIONS
 * ============================================================================ */

// 1) Widget options
$slider_opt = get_option('widget_editorial_featured_slider', array());
$slider_opt = $slider_opt + $slider_widgets; // merge (no pisa si ya existen)
update_option('widget_editorial_featured_slider', $slider_opt);
echo "widget_editorial_featured_slider updated: " . count($slider_opt) . " total\n";

$block_opt = get_option('widget_editorial_block_layout', array());
$block_opt = $block_opt + $content_widgets;
update_option('widget_editorial_block_layout', $block_opt);
echo "widget_editorial_block_layout updated: " . count($block_opt) . " total\n";

// 2) Widgets WP estándar (recent posts + categories)
$recent_opt = get_option('widget_recent-posts', array());
$recent_opt = $recent_opt + $sidebar_widgets;
update_option('widget_recent-posts', $recent_opt);
echo "widget_recent-posts updated: " . count($recent_opt) . " total\n";

$cat_opt = get_option('widget_categories', array());
if (empty($cat_opt) || !isset($cat_opt[8])) {
    $cat_opt[8] = array(
        'title' => 'Categorías',
        'count' => 0,
        'hierarchical' => 0,
        'dropdown' => 0,
    );
    update_option('widget_categories', $cat_opt);
}
echo "widget_categories updated\n";

// 3) sidebars_widgets — asignar a los widget areas
$sidebars = get_option('sidebars_widgets', array());

// Limpiar las 3 areas de magazine (dejarlas vacías primero)
$magazine_areas = array(
    'editorial_home_slider_area',
    'editorial_home_content_area',
    'editorial_home_sidebar',
);

foreach ($magazine_areas as $area) {
    $sidebars[$area] = array();
}

// Slider area
$sidebars['editorial_home_slider_area'][] = 'editorial_featured_slider-1';

// Content area — block layouts
$sidebars['editorial_home_content_area'][] = 'editorial_block_layout-2';
$sidebars['editorial_home_content_area'][] = 'editorial_block_layout-3';
$sidebars['editorial_home_content_area'][] = 'editorial_block_layout-4';
$sidebars['editorial_home_content_area'][] = 'editorial_block_layout-5';
$sidebars['editorial_home_content_area'][] = 'editorial_block_layout-6';

// Sidebar
$sidebars['editorial_home_sidebar'][] = 'recent-posts-7';
$sidebars['editorial_home_sidebar'][] = 'categories-8';

update_option('sidebars_widgets', $sidebars);
echo "sidebars_widgets updated\n";

// 4) Asegurar que la página Magazine use el template
$mag_id = (int) getenv('MAG_ID');
if ($mag_id > 0) {
    update_post_meta($mag_id, '_wp_page_template', 'templates/magazine-template.php');
    echo "Magazine template assigned to page $mag_id\n";
}

echo "=== Magazine widgets bootstrap done ===\n";
