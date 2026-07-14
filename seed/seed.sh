#!/bin/bash
# periodico2 - One-shot WordPress bootstrap (Public Opinion style)
set -e

DB_HOST="${WORDPRESS_DB_HOST:-127.0.0.1}"
DB_USER="${WORDPRESS_DB_USER:-periodico2}"
DB_PASS="${WORDPRESS_DB_PASSWORD:-P3r10d1c02_M4r1adb_2026!}"
DB_NAME="${WORDPRESS_DB_NAME:-periodico2}"

export WORDPRESS_DB_HOST="$DB_HOST"
export WORDPRESS_DB_USER="$DB_USER"
export WORDPRESS_DB_PASSWORD="$DB_PASS"
export WORDPRESS_DB_NAME="$DB_NAME"

echo "==> WordPress DB target: $DB_USER@$DB_HOST/$DB_NAME"

cd /var/www/html

# Wait for DB
for i in {1..30}; do
  if wp --path=/var/www/html db check --allow-root 2>/dev/null; then
    echo "  db OK"
    break
  fi
  echo "  waiting for db ($i)..."
  sleep 2
done

# Install WP if not installed
if ! wp --path=/var/www/html core is-installed --allow-root 2>/dev/null; then
  echo "==> Installing WordPress core"
  wp --path=/var/www/html core install \
    --url="${WP_SITEURL:-https://periodico2.statusloop.app}" \
    --title="${WP_TITLE:-Periodico2}" \
    --admin_user="${WP_ADMIN_USER:-admin}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL:-admin@periodico2.statusloop.app}" \
    --skip-email --allow-root
else
  echo "==> WordPress ya instalado, saltando install"
fi

echo "==> Site settings"
wp --path=/var/www/html option update blogdescription "${WP_TAGLINE:-El periódico digital — estilo Public Opinion}" --allow-root
wp --path=/var/www/html option update timezone_string "America/Santo_Domingo" --allow-root
wp --path=/var/www/html option update date_format "d/m/Y" --allow-root
wp --path=/var/www/html option update time_format "H:i" --allow-root
wp --path=/var/www/html option update start_of_week "1" --allow-root
wp --path=/var/www/html option update posts_per_page "10" --allow-root
wp --path=/var/www/html option update default_comment_status "open" --allow-root
wp --path=/var/www/html option update show_on_front "posts" --allow-root

echo "==> Permalinks"
wp --path=/var/www/html rewrite structure "/%postname%/" --allow-root
wp --path=/var/www/html rewrite flush --hard --allow-root

echo "==> News Portal theme (magazine grid - Public Opinion style)"
# News Portal es un theme magazine-style gratuito de ThemeEgg con grid layouts
# Lo customizamos con CSS para asemejar Public Opinion de CSSIgniter
if ! wp --path=/var/www/html theme is-installed news-portal --allow-root 2>/dev/null; then
  echo "  Instalando News Portal..."
  wp --path=/var/www/html theme install news-portal --allow-root 2>&1 | tail -3
fi
wp --path=/var/www/html theme activate news-portal --allow-root 2>&1 | tail -1

# Companion plugin (ThemeEgg Demo Importer / Toolkit)
if ! wp --path=/var/www/html plugin is-installed themeegg-companion --allow-root 2>/dev/null; then
  wp --path=/var/www/html plugin install themeegg-companion --allow-root 2>&1 | tail -2
fi
wp --path=/var/www/html plugin activate themeegg-companion --allow-root 2>&1 | tail -1

# News Portal options
wp --path=/var/www/html option update news_portal_site_layout "wide" --allow-root
wp --path=/var/www/html option update news_portal_primary_color "c0392b" --allow-root
wp --path=/var/www/html option update news_portal_breaking_news_title "BREAKING" --allow-root
wp --path=/var/www/html option update news_portal_enable_breaking_news "1" --allow-root
wp --path=/var/www/html option update news_portal_blog_excerpt_length "30" --allow-root
wp --path=/var/www/html option update news_portal_header_text "Periodico2" --allow-root

# Custom CSS que recrea el estilo de Public Opinion
echo "==> Custom CSS (Public Opinion look)"
CSS_ID=$(wp --path=/var/www/html post list --post_type=custom_css --field=ID --allow-root 2>/dev/null | head -1)
if [ -z "$CSS_ID" ]; then
  CSS_ID=$(wp --path=/var/www/html post create /seed/custom.css \
    --post_type=custom_css \
    --post_status=publish \
    --post_title="Periodico2 Custom CSS - Public Opinion style" \
    --allow-root 2>&1 | grep -oE 'Created post [0-9]+' | grep -oE '[0-9]+' | head -1)
fi
[ -n "$CSS_ID" ] && wp --path=/var/www/html option update custom_css_post_id "$CSS_ID" --allow-root
echo "  Custom CSS post ID: $CSS_ID"

echo "==> Essential plugins"
for PLUGIN in akismet contact-form-7 classic-editor seo-by-rank-math; do
  if ! wp --path=/var/www/html plugin is-installed "$PLUGIN" --allow-root 2>/dev/null; then
    wp --path=/var/www/html plugin install "$PLUGIN" --allow-root 2>&1 | tail -2
  fi
  wp --path=/var/www/html plugin activate "$PLUGIN" --allow-root 2>&1 | tail -1
done
wp --path=/var/www/html option update classic-editor-replace "classic" --allow-root
wp --path=/var/www/html option update classic-editor-allow-users "allow" --allow-root

echo "==> Categories"
declare -A SECTIONS=(
  [politica]="Politica"
  [economia]="Economia"
  [mundo]="Mundo"
  [tecnologia]="Tecnologia"
  [deportes]="Deportes"
  [cultura]="Cultura"
  [opinion]="Opinion"
  [estilo]="Estilo de Vida"
)
for SLUG in "${!SECTIONS[@]}"; do
  wp --path=/var/www/html term create category "${SECTIONS[$SLUG]}" --slug="$SLUG" --description="Sección de ${SECTIONS[$SLUG]}" --allow-root 2>/dev/null || true
done

echo "==> Navigation menu"
if ! wp --path=/var/www/html menu list --allow-root 2>/dev/null | grep -q "Menú Principal"; then
  wp --path=/var/www/html menu create "Menú Principal" --allow-root 2>&1 | tail -1
fi
echo "  Limpiando items del menu..."
# Limpiar items de forma segura (sin colgar si el output es inesperado)
EXISTING_ITEMS=$(timeout 10 wp --path=/var/www/html menu item list "Menú Principal" --field=db_id --format=ids --allow-root 2>/dev/null | head -50)
if [ -n "$EXISTING_ITEMS" ]; then
  for ITEM_ID in $EXISTING_ITEMS; do
    [ -n "$ITEM_ID" ] && timeout 5 wp --path=/var/www/html menu item delete "$ITEM_ID" --allow-root 2>/dev/null
  done
fi
echo "  Agregando items..."
for SLUG in politica economia mundo tecnologia deportes cultura opinion estilo; do
  CAT_ID=$(wp --path=/var/www/html term list category --slug="$SLUG" --field=term_id --allow-root 2>/dev/null | head -1)
  if [ -n "$CAT_ID" ]; then
    timeout 10 wp --path=/var/www/html menu item add-custom \
      "Menú Principal" \
      "$(echo "$SLUG" | sed 's/^./\U&/' | sed 's/estilo/Estilo/')" \
      "/category/$SLUG/" \
      --allow-root 2>&1 | tail -1
  fi
done
# Add "Home" link as first item
timeout 10 wp --path=/var/www/html menu item add-custom "Menú Principal" "Home" "/" --allow-root 2>&1 | tail -1

# Asignar menu via PHP
MENU_ID=$(wp --path=/var/www/html menu list --fields=term_id,name --allow-root 2>/dev/null | awk -F'|' '/Menú Principal/ {gsub(/ /,"",$1); print $1; exit}')
if [ -n "$MENU_ID" ]; then
  echo "==> Asignando menu $MENU_ID via PHP"
  CULTURINFO_MENU_ID=$MENU_ID wp --path=/var/www/html eval-file /seed/assign_menu.php --allow-root 2>&1 | tail -20

  # Borra Sample Page y Hello World
  SAMPLE_ID=$(wp --path=/var/www/html post list --post_type=page --name="sample-page" --field=ID --allow-root 2>/dev/null | head -1)
  [ -n "$SAMPLE_ID" ] && wp --path=/var/www/html post delete "$SAMPLE_ID" --force --allow-root 2>&1 | tail -1
  wp --path=/var/www/html post delete 1 --force --allow-root 2>/dev/null || true
fi

# Frontmatter parser
parse_frontmatter() {
  local FILE="$1"
  local FIELD="$2"
  sed -n "/^${FIELD}:/p" "$FILE" | head -1 | sed "s/^${FIELD}:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//' | sed "s/'$//" | sed "s/'\$//"
}

parse_categories() {
  local FILE="$1"
  local VAL=$(parse_frontmatter "$FILE" categories)
  if [[ "$VAL" == \[* ]]; then
    echo "$VAL" | tr -d '[]' | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '\n' ',' | sed 's/,$//'
  elif [[ -n "$VAL" ]]; then
    echo "$VAL"
  else
    awk '/^categories:/{f=1; next} f && /^- /{sub(/^- /,""); gsub(/[[:space:]]/,""); print; f=0; next} f && /^[^ -]/{f=0}' "$FILE" | tr '\n' ',' | sed 's/,$//'
  fi
}

echo "==> Sample articles"
EXISTING=$(wp --path=/var/www/html post list --post_type=post --post_status=publish --format=count --allow-root 2>/dev/null | tr -d ' ')
if [ "${EXISTING:-0}" -lt 6 ]; then
  wp --path=/var/www/html post delete $(wp --path=/var/www/html post list --post_type=post --post_status=publish --format=ids --allow-root 2>/dev/null) --force --allow-root 2>/dev/null || true

  for FILE in /seed/articles/*.md; do
    [ -f "$FILE" ] || continue
    SLUG=$(basename "$FILE" .md | sed 's/^[0-9]*-//')
    TITLE=$(parse_frontmatter "$FILE" title)
    CATS=$(parse_categories "$FILE")
    CATS_CLEAN=$(echo "$CATS" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^\*\*//;s/\*\*$//' | tr '\n' ',' | sed 's/,$//')

    echo "  + $SLUG | cat=[$CATS_CLEAN] | title='$TITLE'"
    if [ -n "$CATS_CLEAN" ]; then
      awk 'BEGIN{fm=0} /^---$/{fm=!fm; next} !fm{print}' "$FILE" | \
        sed 's/^#\+[[:space:]]*//' | sed 's/\*\*//g' | sed 's/^>//' | \
        wp --path=/var/www/html post create - \
        --post_type=post --post_status=publish \
        --post_title="$TITLE" --post_name="$SLUG" \
        --post_excerpt="$TITLE." \
        --post_category="$CATS_CLEAN" \
        --allow-root 2>&1 | tail -1
    else
      awk 'BEGIN{fm=0} /^---$/{fm=!fm; next} !fm{print}' "$FILE" | \
        sed 's/^#\+[[:space:]]*//' | sed 's/\*\*//g' | sed 's/^>//' | \
        wp --path=/var/www/html post create - \
        --post_type=post --post_status=publish \
        --post_title="$TITLE" --post_name="$SLUG" \
        --post_excerpt="$TITLE." \
        --allow-root 2>&1 | tail -1
    fi

    # Featured image
    IMG_URL=$(grep '^featured_image:' "$FILE" | head -1 | sed 's/^featured_image:[[:space:]]*//' | sed 's/^"//;s/"$//')
    if [ -n "$IMG_URL" ]; then
      POST_ID=$(wp --path=/var/www/html post list --post_type=post --name="$SLUG" --field=ID --allow-root 2>/dev/null | head -1)
      if [ -n "$POST_ID" ]; then
        CURRENT_THUMB=$(wp --path=/var/www/html post get "$POST_ID" --field=meta_value --meta_key=_thumbnail_id --allow-root 2>/dev/null | head -1)
        if [ -z "$CURRENT_THUMB" ]; then
          echo "    downloading $IMG_URL"
          curl -sL --max-time 30 -o /tmp/feat.jpg "$IMG_URL" 2>/dev/null
          if [ -s /tmp/feat.jpg ] && [ "$(stat -c%s /tmp/feat.jpg 2>/dev/null)" -gt 1000 ]; then
            wp --path=/var/www/html media import /tmp/feat.jpg --post_id="$POST_ID" --featured_image --allow-root 2>&1 | tail -1
          fi
        fi
      fi
    fi
  done
fi

echo "==> ✓ Bootstrap done"
wp --path=/var/www/html post list --post_type=post --post_status=publish --format=count --allow-root
