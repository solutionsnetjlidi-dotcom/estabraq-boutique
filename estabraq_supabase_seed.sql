-- ══════════════════════════════════════════════════════════════════════
--  ESTABRAK — Hijab & Modest Elegance
--  Supabase Complete Schema + Seed Data v3.0
--  Djerba, Tunisie — 2026
--
--  INSTRUCTIONS :
--  1. Supabase → SQL Editor → New query
--  2. Coller tout ce fichier (Ctrl+A puis Ctrl+C dans ce fichier)
--  3. Cliquer "Run" (bouton vert) ou Ctrl+Enter
--  4. Vérifier le message de succès en bas
-- ══════════════════════════════════════════════════════════════════════

-- ── Extensions ────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ══════════════════════════════════════════════════════════════════════
--  PARTIE 1 : SUPPRESSION DES ANCIENNES TABLES (si elles existent)
--  Ordre important : tables enfants avant tables parents
-- ══════════════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS admin_notifications  CASCADE;
DROP TABLE IF EXISTS contact_messages     CASCADE;
DROP TABLE IF EXISTS site_settings        CASCADE;
DROP TABLE IF EXISTS coupons              CASCADE;
DROP TABLE IF EXISTS reviews              CASCADE;
DROP TABLE IF EXISTS rentals              CASCADE;
DROP TABLE IF EXISTS order_items          CASCADE;
DROP TABLE IF EXISTS orders               CASCADE;
DROP TABLE IF EXISTS customers            CASCADE;
DROP TABLE IF EXISTS product_media        CASCADE;
DROP TABLE IF EXISTS products             CASCADE;
DROP TABLE IF EXISTS categories           CASCADE;

-- ══════════════════════════════════════════════════════════════════════
--  PARTIE 2 : CRÉATION DES TABLES
-- ══════════════════════════════════════════════════════════════════════

-- ── 1. Catégories ─────────────────────────────────────────────────────
CREATE TABLE categories (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  name_ar     TEXT        NOT NULL,
  name_fr     TEXT,
  name_en     TEXT,
  slug        TEXT        UNIQUE NOT NULL,
  description TEXT,
  sort_order  INTEGER     DEFAULT 0,
  is_active   BOOLEAN     DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. Produits ───────────────────────────────────────────────────────
CREATE TABLE products (
  id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  category_id         UUID        REFERENCES categories(id) ON DELETE SET NULL,
  slug                TEXT        UNIQUE NOT NULL,
  name_ar             TEXT        NOT NULL,
  name_fr             TEXT,
  name_en             TEXT,
  description_ar      TEXT,
  description_fr      TEXT,
  description_en      TEXT,
  price               NUMERIC(10,3) NOT NULL DEFAULT 0,
  rent_price_per_day  NUMERIC(10,3),
  deposit_amount      NUMERIC(10,3),
  stock_quantity      INTEGER     DEFAULT 0,
  sizes               TEXT[]      DEFAULT '{}',
  colors              TEXT[]      DEFAULT '{}',
  tags                TEXT[]      DEFAULT '{}',
  badge               TEXT,
  category            TEXT,
  is_active           BOOLEAN     DEFAULT true,
  is_featured         BOOLEAN     DEFAULT false,
  available_rent      BOOLEAN     DEFAULT false,
  sort_order          INTEGER     DEFAULT 0,
  meta_title          TEXT,
  meta_description    TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. Médias produits ────────────────────────────────────────────────
CREATE TABLE product_media (
  id           UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id   UUID        REFERENCES products(id) ON DELETE CASCADE,
  storage_path TEXT        NOT NULL,
  alt_text     TEXT,
  is_primary   BOOLEAN     DEFAULT false,
  sort_order   INTEGER     DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── 4. Clientes ───────────────────────────────────────────────────────
CREATE TABLE customers (
  id           UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name    TEXT        NOT NULL,
  phone        TEXT,
  email        TEXT,
  city         TEXT,
  address      TEXT,
  wilaya       TEXT,
  country      TEXT        DEFAULT 'TN',
  notes        TEXT,
  total_orders INTEGER     DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── 5. Commandes ──────────────────────────────────────────────────────
CREATE TABLE orders (
  id               UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id      UUID        REFERENCES customers(id) ON DELETE SET NULL,
  status           TEXT        DEFAULT 'pending'
                   CHECK (status IN ('pending','confirmed','shipped','delivered','cancelled','refunded')),
  payment_method   TEXT        DEFAULT 'cod'
                   CHECK (payment_method IN ('cod','bank_transfer','paypal','card')),
  payment_status   TEXT        DEFAULT 'pending'
                   CHECK (payment_status IN ('pending','paid','failed','refunded')),
  subtotal         NUMERIC(10,3) DEFAULT 0,
  discount_amount  NUMERIC(10,3) DEFAULT 0,
  delivery_cost    NUMERIC(10,3) DEFAULT 7,
  total            NUMERIC(10,3) DEFAULT 0,
  coupon_code      TEXT,
  notes            TEXT,
  delivery_address TEXT,
  tracking_number  TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ── 6. Articles de commande ───────────────────────────────────────────
CREATE TABLE order_items (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id    UUID        REFERENCES orders(id) ON DELETE CASCADE,
  product_id  UUID        REFERENCES products(id) ON DELETE SET NULL,
  quantity    INTEGER     DEFAULT 1,
  unit_price  NUMERIC(10,3) NOT NULL,
  size        TEXT,
  color       TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 7. Locations ──────────────────────────────────────────────────────
CREATE TABLE rentals (
  id               UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id       UUID        REFERENCES products(id) ON DELETE SET NULL,
  order_id         UUID        REFERENCES orders(id) ON DELETE SET NULL,
  customer_id      UUID        REFERENCES customers(id) ON DELETE SET NULL,
  status           TEXT        DEFAULT 'pending'
                   CHECK (status IN ('pending','active','returned','cancelled','overdue')),
  start_date       DATE,
  end_date         DATE,
  daily_rate       NUMERIC(10,3) DEFAULT 0,
  deposit_paid     NUMERIC(10,3) DEFAULT 0,
  deposit_returned BOOLEAN     DEFAULT false,
  size             TEXT,
  color            TEXT,
  notes            TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ── 8. Avis clients ───────────────────────────────────────────────────
CREATE TABLE reviews (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id        UUID        REFERENCES products(id) ON DELETE CASCADE,
  order_id          UUID        REFERENCES orders(id) ON DELETE SET NULL,
  reviewer_name     TEXT        NOT NULL,
  reviewer_email    TEXT,
  reviewer_flag     TEXT        DEFAULT '🇹🇳',
  reviewer_location TEXT,
  rating            INTEGER     DEFAULT 5 CHECK (rating BETWEEN 1 AND 5),
  comment_ar        TEXT,
  comment_fr        TEXT,
  comment_en        TEXT,
  is_approved       BOOLEAN     DEFAULT false,
  is_featured       BOOLEAN     DEFAULT false,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ── 9. Coupons ────────────────────────────────────────────────────────
CREATE TABLE coupons (
  id             UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  code           TEXT        UNIQUE NOT NULL,
  description    TEXT,
  discount_type  TEXT        DEFAULT 'percentage'
                 CHECK (discount_type IN ('percentage','fixed')),
  discount_value NUMERIC(10,3) NOT NULL,
  min_purchase   NUMERIC(10,3) DEFAULT 0,
  max_uses       INTEGER,
  current_uses   INTEGER     DEFAULT 0,
  is_active      BOOLEAN     DEFAULT true,
  expires_at     TIMESTAMPTZ,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ── 10. Messages contact ──────────────────────────────────────────────
CREATE TABLE contact_messages (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  name        TEXT        NOT NULL,
  email       TEXT,
  phone       TEXT,
  subject     TEXT,
  message     TEXT        NOT NULL,
  lang        TEXT        DEFAULT 'fr',
  is_read     BOOLEAN     DEFAULT false,
  replied_at  TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 11. Paramètres du site ────────────────────────────────────────────
CREATE TABLE site_settings (
  id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  key        TEXT        UNIQUE NOT NULL,
  value      TEXT,
  label      TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 12. Notifications admin ───────────────────────────────────────────
CREATE TABLE admin_notifications (
  id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  type       TEXT        NOT NULL,
  title      TEXT,
  message    TEXT,
  is_read    BOOLEAN     DEFAULT false,
  data       JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════════════
--  PARTIE 3 : INDEX (Performances)
-- ══════════════════════════════════════════════════════════════════════

CREATE INDEX idx_products_category   ON products(category_id);
CREATE INDEX idx_products_active     ON products(is_active);
CREATE INDEX idx_products_featured   ON products(is_featured);
CREATE INDEX idx_products_slug       ON products(slug);
CREATE INDEX idx_products_category_t ON products(category);
CREATE INDEX idx_product_media_prod  ON product_media(product_id);
CREATE INDEX idx_orders_customer     ON orders(customer_id);
CREATE INDEX idx_orders_status       ON orders(status);
CREATE INDEX idx_orders_created      ON orders(created_at DESC);
CREATE INDEX idx_order_items_order   ON order_items(order_id);
CREATE INDEX idx_rentals_product     ON rentals(product_id);
CREATE INDEX idx_rentals_status      ON rentals(status);
CREATE INDEX idx_reviews_approved    ON reviews(is_approved);
CREATE INDEX idx_coupons_code        ON coupons(code);
CREATE INDEX idx_settings_key        ON site_settings(key);

-- ══════════════════════════════════════════════════════════════════════
--  PARTIE 4 : TRIGGERS (updated_at automatique)
-- ══════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_updated
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_orders_updated
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_rentals_updated
  BEFORE UPDATE ON rentals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_customers_updated
  BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════════════════
--  PARTIE 5 : SÉCURITÉ — ROW LEVEL SECURITY (RLS)
-- ══════════════════════════════════════════════════════════════════════

-- Activer RLS sur toutes les tables
ALTER TABLE categories          ENABLE ROW LEVEL SECURITY;
ALTER TABLE products            ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_media       ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers           ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders              ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items         ENABLE ROW LEVEL SECURITY;
ALTER TABLE rentals             ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews             ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons             ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_messages    ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_settings       ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;

-- Lecture publique (frontend boutique)
CREATE POLICY "estabrak_public_read_products"
  ON products FOR SELECT USING (is_active = true);

CREATE POLICY "estabrak_public_read_categories"
  ON categories FOR SELECT USING (is_active = true);

CREATE POLICY "estabrak_public_read_reviews"
  ON reviews FOR SELECT USING (is_approved = true);

CREATE POLICY "estabrak_public_read_settings"
  ON site_settings FOR SELECT USING (true);

CREATE POLICY "estabrak_public_read_media"
  ON product_media FOR SELECT USING (true);

CREATE POLICY "estabrak_public_read_coupons"
  ON coupons FOR SELECT USING (is_active = true);

-- Insertion publique (clientes du frontend)
CREATE POLICY "estabrak_public_insert_customers"
  ON customers FOR INSERT WITH CHECK (true);

CREATE POLICY "estabrak_public_insert_orders"
  ON orders FOR INSERT WITH CHECK (true);

CREATE POLICY "estabrak_public_insert_order_items"
  ON order_items FOR INSERT WITH CHECK (true);

CREATE POLICY "estabrak_public_insert_rentals"
  ON rentals FOR INSERT WITH CHECK (true);

CREATE POLICY "estabrak_public_insert_contact"
  ON contact_messages FOR INSERT WITH CHECK (true);

CREATE POLICY "estabrak_public_insert_reviews"
  ON reviews FOR INSERT WITH CHECK (true);

-- Accès admin complet (panneau administration)
CREATE POLICY "estabrak_admin_all_products"
  ON products FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "estabrak_admin_all_categories"
  ON categories FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "estabrak_admin_all_media"
  ON product_media FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "estabrak_admin_all_customers"
  ON customers FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "estabrak_admin_all_orders"
  ON orders FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "estabrak_admin_all_order_items"
  ON order_items FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "estabrak_admin_all_rentals"
  ON rentals FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "estabrak_admin_all_reviews"
  ON reviews FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "estabrak_admin_all_coupons"
  ON coupons FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "estabrak_admin_all_contact"
  ON contact_messages FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "estabrak_admin_all_settings"
  ON site_settings FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "estabrak_admin_all_notifications"
  ON admin_notifications FOR ALL USING (true) WITH CHECK (true);

-- ══════════════════════════════════════════════════════════════════════
--  PARTIE 6 : DONNÉES INITIALES (SEED DATA)
-- ══════════════════════════════════════════════════════════════════════

-- ── Catégories ESTABRAK ───────────────────────────────────────────────
INSERT INTO categories (name_ar, name_fr, name_en, slug, sort_order, is_active) VALUES
  ('حجابات',      'Hijabs',       'Hijabs',       'hijab',      1, true),
  ('جلابيب',      'Jilbabs',      'Jilbabs',      'jilbab',     2, true),
  ('طرح وأوشحة',  'Voiles',       'Veils',         'voile',      3, true),
  ('خمارات',      'Khimars',      'Khimars',      'khimar',     4, true),
  ('إكسسوارات',   'Accessoires',  'Accessories',  'accessoire', 5, true),
  ('أطقم كاملة',  'Sets & Packs', 'Sets & Packs', 'set',        6, true);

-- ── Produits ESTABRAK (12 produits Hijab & Modest Fashion) ───────────

-- HIJABS
INSERT INTO products (
  category_id, category, slug,
  name_ar, name_fr, name_en,
  description_ar, description_fr, description_en,
  price, rent_price_per_day, deposit_amount,
  stock_quantity, sizes, colors, tags, badge,
  is_active, is_featured, available_rent
)
SELECT
  c.id, 'hijab', p.slug,
  p.name_ar, p.name_fr, p.name_en,
  p.desc_ar, p.desc_fr, p.desc_en,
  p.price, p.rent, p.deposit,
  p.stock, p.sizes, p.colors, p.tags, p.badge,
  true, p.featured, p.rentable
FROM categories c,
(VALUES
  (
    'hijab-mousseline-premium-signature',
    'حجاب موسلين بريميوم سيجنتشر',
    'Hijab Mousseline Premium Signature',
    'Premium Chiffon Hijab Signature',
    'حجابنا الأيقوني من الموسلين البريميوم. خفيف، سلس، غير شفاف. يسقط بشكل مثالي ويمنحك إطلالة أنيقة طوال اليوم.',
    'Notre hijab iconique en mousseline premium. Léger, fluide et opaque. Tombe parfaitement pour une allure élégante toute la journée.',
    'Our iconic premium chiffon hijab. Light, fluid and opaque. Falls perfectly for an elegant look all day long.',
    85.000, NULL, NULL, 50,
    ARRAY['Taille Unique'],
    ARRAY['Noir','Ivoire','Beige','Taupe','Camel','Chocolat','Bordeaux','Sauge','Rose Poudré'],
    ARRAY['bestseller','new'], 'best', true, false
  ),
  (
    'hijab-soie-medine-luxe',
    'حجاب حرير المدينة الفاخر',
    'Hijab Soie de Médine Luxe',
    'Medina Silk Luxury Hijab',
    'حجاب من حرير المدينة بنعومة لا مثيل لها. مثالي للمناسبات الخاصة والأعياد. يعكس الضوء بشكل ساحر.',
    'Un voile en soie de Médine d''une douceur incomparable. Idéal pour les occasions spéciales et les fêtes. Reflet de lumière enchanteur.',
    'A veil in Medina silk of incomparable softness. Ideal for special occasions. Enchanting light reflection.',
    120.000, NULL, NULL, 30,
    ARRAY['Taille Unique'],
    ARRAY['Noir','Bordeaux','Bleu Nuit','Champagne','Ivoire','Moka'],
    ARRAY['featured','premium'], 'limited', true, false
  ),
  (
    'hijab-jersey-modal-quotidien',
    'حجاب جيرسي مودال للاستخدام اليومي',
    'Hijab Jersey Modal Quotidien',
    'Daily Modal Jersey Hijab',
    'الحجاب المثالي للاستخدام اليومي. قماش جيرسي مودال فائق النعومة يمنح راحة تامة طوال اليوم.',
    'Le hijab parfait pour le quotidien. Jersey modal ultra-doux pour un confort total toute la journée.',
    'Perfect for everyday wear. Ultra-soft modal jersey for total comfort all day long.',
    65.000, NULL, NULL, 80,
    ARRAY['Taille Unique'],
    ARRAY['Noir','Beige','Taupe','Sauge','Rose Poudré','Chocolat','Camel','Bleu Nuit','Gris Perle'],
    ARRAY['bestseller','new'], 'best', false, false
  ),
  (
    'hijab-crepe-signature-antifroissage',
    'حجاب كريب سيجنتشر مقاوم للتجعد',
    'Hijab Crêpe Signature Anti-froissage',
    'Anti-Crease Crêpe Signature Hijab',
    'حجاب الكريب الأيقوني من استبراك. مقاوم للتجعد بشكل طبيعي، مثالي للمرأة النشطة.',
    'Notre hijab crêpe signature. Anti-froissage naturel, parfait pour les femmes actives.',
    'Our signature crêpe hijab. Naturally anti-crease, perfect for active women.',
    110.000, NULL, NULL, 40,
    ARRAY['Taille Unique'],
    ARRAY['Noir','Bordeaux','Champagne','Chocolat','Moka','Ivoire'],
    ARRAY['featured','new'], 'new', true, false
  )
) AS p(slug, name_ar, name_fr, name_en, desc_ar, desc_fr, desc_en,
       price, rent, deposit, stock, sizes, colors, tags, badge, featured, rentable)
WHERE c.slug = 'hijab';

-- JILBABS
INSERT INTO products (
  category_id, category, slug,
  name_ar, name_fr, name_en,
  description_ar, description_fr, description_en,
  price, rent_price_per_day, deposit_amount,
  stock_quantity, sizes, colors, tags, badge,
  is_active, is_featured, available_rent
)
SELECT
  c.id, 'jilbab', p.slug,
  p.name_ar, p.name_fr, p.name_en,
  p.desc_ar, p.desc_fr, p.desc_en,
  p.price, p.rent, p.deposit,
  p.stock, p.sizes, p.colors, p.tags, p.badge,
  true, p.featured, p.rentable
FROM categories c,
(VALUES
  (
    'jilbab-classique-elegant-noir',
    'جلباب كلاسيكي أنيق - أسود',
    'Jilbab Classique Élégant Noir',
    'Classic Elegant Jilbab Black',
    'جلباب بقصة كلاسيكية منسابة تجمع بين الأصالة والأناقة. قماش مقاوم للتجعد بجودة عالية.',
    'Jilbab aux coupes fluides qui allient tradition et modernité. Tissu anti-froissage de qualité supérieure.',
    'Jilbab with flowing cuts combining tradition and modernity. Premium anti-crease fabric.',
    195.000, 25.000, 50.000, 25,
    ARRAY['S','M','L','XL','XXL'],
    ARRAY['Noir','Moka','Bleu Nuit','Chocolat'],
    ARRAY['bestseller','featured'], 'best', true, true
  ),
  (
    'jilbab-boutonne-moderne-ville',
    'جلباب مزرر عصري للمدينة',
    'Jilbab Boutonné Moderne Ville',
    'Modern Buttoned City Jilbab',
    'جلباب مزرر بتصميم عصري معاصر. قصة خفيفة الاتساع مثالية للمدينة وأماكن العمل.',
    'Jilbab boutonné au style contemporain. Coupe légèrement évasée, parfaite pour la ville et le bureau.',
    'Buttoned jilbab in contemporary style. Slightly flared cut, perfect for the city and office.',
    220.000, 30.000, 60.000, 20,
    ARRAY['S','M','L','XL'],
    ARRAY['Noir','Moka','Camel','Gris Perle','Chocolat'],
    ARRAY['new','featured'], 'new', true, true
  )
) AS p(slug, name_ar, name_fr, name_en, desc_ar, desc_fr, desc_en,
       price, rent, deposit, stock, sizes, colors, tags, badge, featured, rentable)
WHERE c.slug = 'jilbab';

-- VOILES
INSERT INTO products (
  category_id, category, slug,
  name_ar, name_fr, name_en,
  description_ar, description_fr, description_en,
  price, rent_price_per_day, deposit_amount,
  stock_quantity, sizes, colors, tags, badge,
  is_active, is_featured, available_rent
)
SELECT
  c.id, 'voile', p.slug,
  p.name_ar, p.name_fr, p.name_en,
  p.desc_ar, p.desc_fr, p.desc_en,
  p.price, p.rent, p.deposit,
  p.stock, p.sizes, p.colors, p.tags, p.badge,
  true, p.featured, p.rentable
FROM categories c,
(VALUES
  (
    'voile-chiffon-delicat-ceremonies',
    'طرح شيفون ناعم للمناسبات',
    'Voile Chiffon Délicat Cérémonies',
    'Delicate Chiffon Veil for Ceremonies',
    'طرح من الشيفون الناعم الفاخر يمنحك خفة لا مثيل لها. مثالي للمناسبات والحفلات.',
    'Voile en chiffon d''une légèreté exquise. Pour les occasions spéciales et les cérémonies.',
    'Veil in exquisite lightweight chiffon. For special occasions and ceremonies.',
    95.000, 15.000, 30.000, 35,
    ARRAY['Taille Unique'],
    ARRAY['Ivoire','Rose Poudré','Sauge','Champagne','Blanc','Beige'],
    ARRAY['new','featured'], 'new', false, true
  ),
  (
    'voile-nidha-prestige-soirees',
    'طرح نيدها بريستيج للسهرات',
    'Voile Nidha Prestige Soirées',
    'Nidha Prestige Evening Veil',
    'طرح من قماش النيدها الفاخر. سقوط مثالي، معتم وخفيف في نفس الوقت. للمناسبات الكبيرة.',
    'Voile en Nidha de prestige. Tombé parfait, opaque et léger. Pour les grandes occasions.',
    'Prestige Nidha fabric veil. Perfect drape, opaque yet light. For grand occasions.',
    145.000, 20.000, 40.000, 20,
    ARRAY['Taille Unique'],
    ARRAY['Noir','Ivoire','Bordeaux','Bleu Nuit','Moka'],
    ARRAY['featured','premium'], 'limited', true, true
  )
) AS p(slug, name_ar, name_fr, name_en, desc_ar, desc_fr, desc_en,
       price, rent, deposit, stock, sizes, colors, tags, badge, featured, rentable)
WHERE c.slug = 'voile';

-- KHIMARS
INSERT INTO products (
  category_id, category, slug,
  name_ar, name_fr, name_en,
  description_ar, description_fr, description_en,
  price, rent_price_per_day, deposit_amount,
  stock_quantity, sizes, colors, tags, badge,
  is_active, is_featured, available_rent
)
SELECT
  c.id, 'khimar', p.slug,
  p.name_ar, p.name_fr, p.name_en,
  p.desc_ar, p.desc_fr, p.desc_en,
  p.price, p.rent, p.deposit,
  p.stock, p.sizes, p.colors, p.tags, p.badge,
  true, p.featured, p.rentable
FROM categories c,
(VALUES
  (
    'khimar-long-premium-jersey',
    'خمار طويل بريميوم جيرسي',
    'Khimar Long Premium Jersey',
    'Premium Long Jersey Khimar',
    'خمار طويل من الجيرسي البريميوم. يغطي الصدر بالكامل. مريح للاستخدام اليومي.',
    'Khimar long en jersey premium. Couvre entièrement le buste. Confort total pour un port quotidien.',
    'Long premium jersey khimar. Fully covers the chest. Total comfort for daily wear.',
    150.000, NULL, NULL, 30,
    ARRAY['S/M','L/XL'],
    ARRAY['Noir','Chocolat','Bordeaux','Olive','Moka'],
    ARRAY['new','featured'], 'new', true, false
  ),
  (
    'khimar-court-pratique-quotidien',
    'خمار قصير عملي للاستخدام اليومي',
    'Khimar Court Pratique Quotidien',
    'Practical Short Daily Khimar',
    'خمار قصير عملي ومريح للاستخدام اليومي. جيرسي ستريتش بتثبيت ممتاز طوال اليوم.',
    'Khimar court pratique pour le quotidien. Jersey stretch, maintien excellent toute la journée.',
    'Practical short khimar for daily use. Stretch jersey, excellent hold throughout the day.',
    95.000, NULL, NULL, 45,
    ARRAY['Taille Unique'],
    ARRAY['Noir','Moka','Olive','Sauge','Camel'],
    ARRAY['bestseller'], NULL, false, false
  )
) AS p(slug, name_ar, name_fr, name_en, desc_ar, desc_fr, desc_en,
       price, rent, deposit, stock, sizes, colors, tags, badge, featured, rentable)
WHERE c.slug = 'khimar';

-- ACCESSOIRES & SETS
INSERT INTO products (
  category_id, category, slug,
  name_ar, name_fr, name_en,
  description_ar, description_fr, description_en,
  price, stock_quantity, sizes, colors, tags, badge,
  is_active, is_featured, available_rent
)
SELECT
  c.id, 'accessoire', p.slug,
  p.name_ar, p.name_fr, p.name_en,
  p.desc_ar, p.desc_fr, p.desc_en,
  p.price, p.stock, p.sizes, p.colors, p.tags, p.badge,
  true, p.featured, false
FROM categories c,
(VALUES
  (
    'set-hijab-bonnet-luxe-assorti',
    'طقم حجاب وبونيه فاخر متناسق',
    'Set Hijab + Bonnet Luxe Assorti',
    'Luxury Matching Hijab + Bonnet Set',
    'طقم كامل: حجاب من حرير المدينة + بونيه تحت الحجاب متناسق. الثنائي المثالي للأناقة.',
    'Set complet : hijab en soie de Médine + bonnet sous-hijab assorti. Le duo parfait pour l''élégance.',
    'Complete set: Medina silk hijab + matching under-hijab bonnet. The perfect duo for elegance.',
    135.000, 25,
    ARRAY['S','M'],
    ARRAY['Noir','Beige','Taupe','Moka','Ivoire'],
    ARRAY['bestseller','featured'], 'best', true
  ),
  (
    'epingles-hijab-premium-pack10',
    'دبابيس حجاب بريميوم - عبوة 10 قطع',
    'Épingles à Hijab Premium - Pack 10',
    'Premium Hijab Pins - Pack of 10',
    'دبابيس حجاب من المعدن البريميوم. رأس مطلية بالذهب أو الفضة. عبوة من 10 دبابيس متنوعة.',
    'Épingles à hijab en métal premium. Tête plaquée or ou argent. Set de 10 épingles assorties.',
    'Premium metal hijab pins. Gold or silver plated head. Set of 10 assorted pins.',
    25.000, 100,
    ARRAY['Pack 10'],
    ARRAY['Or','Argent','Champagne','Rosé Gold'],
    ARRAY['new'], NULL, false
  )
) AS p(slug, name_ar, name_fr, name_en, desc_ar, desc_fr, desc_en,
       price, stock, sizes, colors, tags, badge, featured)
WHERE c.slug = 'accessoire';

-- ── Images des produits ───────────────────────────────────────────────
INSERT INTO product_media (product_id, storage_path, alt_text, is_primary, sort_order)
SELECT
  p.id,
  CASE p.slug
    WHEN 'hijab-mousseline-premium-signature'  THEN 'https://images.unsplash.com/photo-1594552072238-b8a33785b261?w=800&h=1067&fit=crop'
    WHEN 'hijab-soie-medine-luxe'              THEN 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=800&h=1067&fit=crop'
    WHEN 'hijab-jersey-modal-quotidien'        THEN 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800&h=1067&fit=crop'
    WHEN 'hijab-crepe-signature-antifroissage' THEN 'https://images.unsplash.com/photo-1544022613-e87ca75a784a?w=800&h=1067&fit=crop'
    WHEN 'jilbab-classique-elegant-noir'       THEN 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=800&h=1067&fit=crop'
    WHEN 'jilbab-boutonne-moderne-ville'       THEN 'https://images.unsplash.com/photo-1585487000160-6ebcfceb0d03?w=800&h=1067&fit=crop'
    WHEN 'voile-chiffon-delicat-ceremonies'    THEN 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&h=1067&fit=crop'
    WHEN 'voile-nidha-prestige-soirees'        THEN 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=800&h=1067&fit=crop'
    WHEN 'khimar-long-premium-jersey'          THEN 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=800&h=1067&fit=crop'
    WHEN 'khimar-court-pratique-quotidien'     THEN 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&h=1067&fit=crop'
    WHEN 'set-hijab-bonnet-luxe-assorti'       THEN 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=800&h=1067&fit=crop'
    WHEN 'epingles-hijab-premium-pack10'       THEN 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&h=1067&fit=crop'
    ELSE 'https://images.unsplash.com/photo-1594552072238-b8a33785b261?w=800&h=1067&fit=crop'
  END,
  p.name_fr || ' — ESTABRAK Hijab & Modest Elegance',
  true,
  0
FROM products p;

-- ── Avis clients ESTABRAK ─────────────────────────────────────────────
INSERT INTO reviews (
  reviewer_name, reviewer_flag, reviewer_location,
  rating, comment_fr, comment_ar, comment_en,
  is_approved, is_featured
) VALUES
(
  'Fatima Z.', '🇲🇦', 'Casablanca, Maroc', 5,
  'Un hijab d''une qualité incomparable. Le tombé est parfait et le tissu est tellement doux que je ne veux plus l''enlever !',
  'جودة لا مثيل لها. يسقط بشكل مثالي والقماش ناعم جداً لدرجة أنني لا أريد خلعه!',
  'Incomparable quality. The drape is perfect and the fabric is so soft I never want to take it off!',
  true, true
),
(
  'Aisha M.', '🇸🇦', 'Riyad, Arabie Saoudite', 5,
  'Le jilbab ESTABRAK est exactement ce que je cherchais. Élégant, pudique et tellement confortable.',
  'جلباب ESTABRAK هو بالضبط ما كنت أبحث عنه. أنيق ومحتشم ومريح جداً.',
  'The ESTABRAK jilbab is exactly what I was looking for. Elegant, modest and so comfortable.',
  true, true
),
(
  'Sarah B.', '🇫🇷', 'Paris, France', 5,
  'Livraison rapide depuis la Tunisie et emballage très soigné. Le hijab en mousseline est encore plus beau en réalité !',
  'توصيل سريع من تونس وتغليف أنيق جداً. حجاب الموسلين أجمل بكثير في الواقع!',
  'Fast delivery from Tunisia and very careful packaging. The chiffon hijab is even more beautiful in reality!',
  true, true
),
(
  'Nour H.', '🇹🇳', 'Tunis, Tunisie', 5,
  'J''achète maintenant tous mes hijabs chez ESTABRAK. Qualité irréprochable et service client parfait.',
  'أشتري الآن كل حجاباتي من ESTABRAK. جودة لا تشوبها شائبة وخدمة عملاء مثالية.',
  'I now buy all my hijabs from ESTABRAK. Irreproachable quality and perfect customer service.',
  true, false
),
(
  'Zineb R.', '🇩🇪', 'Berlin, Allemagne', 4,
  'Très belle collection de khimars. Le tissu est premium et le maintien est excellent. Je recommande !',
  'مجموعة رائعة من الخمارات. القماش بريميوم والتثبيت ممتاز. أنصح به!',
  'Very beautiful khimar collection. The fabric is premium and the hold is excellent. I recommend!',
  true, false
),
(
  'Imane K.', '🇩🇿', 'Alger, Algérie', 5,
  'Le set hijab + bonnet est parfait. Les deux vont parfaitement ensemble. Livraison en Algérie impeccable !',
  'طقم الحجاب والبونيه مثالي. الاثنان يتناسبان بشكل مثالي. التوصيل إلى الجزائر كان ممتازاً!',
  'The hijab + bonnet set is perfect. Both match perfectly. Delivery to Algeria was impeccable!',
  true, true
),
(
  'Yasmin Al-F.', '🇶🇦', 'Doha, Qatar', 5,
  'Des produits de qualité exceptionnelle. Le hijab en soie de Médine est magnifique pour les occasions.',
  'منتجات ذات جودة استثنائية. حجاب حرير المدينة رائع للمناسبات.',
  'Products of exceptional quality. The Medina silk hijab is magnificent for occasions.',
  true, true
),
(
  'Hana M.', '🇧🇪', 'Bruxelles, Belgique', 5,
  'Première commande et je suis conquise ! Le voile en chiffon est d''une légèreté extraordinaire.',
  'أول طلب وقد انبهرت تماماً! طرح الشيفون بخفة لا مثيل لها.',
  'First order and I am won over! The chiffon veil is of extraordinary lightness.',
  true, false
);

-- ── Coupons de réduction ESTABRAK ─────────────────────────────────────
INSERT INTO coupons (
  code, description, discount_type, discount_value,
  min_purchase, max_uses, is_active
) VALUES
  ('ESTABRAK10', 'Bienvenue — 10% sur votre première commande',   'percentage', 10,  100.000, 500, true),
  ('HIJAB20',    '20% sur tous les hijabs — offre limitée',       'percentage', 20,  150.000, 100, true),
  ('JILBAB15',   '15% sur les jilbabs et khimars',               'percentage', 15,  200.000, 200, true),
  ('WELCOME50',  '50 TND de réduction — commande min. 300 TND',  'fixed',       50,  300.000, 150, true),
  ('VIP25',      'Code VIP — 25% pour nos meilleures clientes',  'percentage', 25,  400.000,  50, true),
  ('EID2026',    'Spécial Aïd 2026 — 12% sur tout le site',     'percentage', 12,   80.000, 1000,true),
  ('NOEL2026',   'Spécial Noël — 10 TND offerts',               'fixed',       10,   70.000, 300, true);

-- ── Paramètres du site ESTABRAK ───────────────────────────────────────
INSERT INTO site_settings (key, value, label) VALUES
  ('site_name_fr',      'ESTABRAK',                                       'Nom du site (FR)'),
  ('site_name_ar',      'استبراك',                                         'اسم الموقع (AR)'),
  ('site_name_en',      'ESTABRAK',                                       'Site name (EN)'),
  ('tagline_fr',        'Hijab & Modest Elegance',                        'Slogan (FR)'),
  ('tagline_ar',        'الحجاب والأناقة المحتشمة',                        'الشعار (AR)'),
  ('whatsapp_number',   '+21654421123',                                   'رقم واتساب'),
  ('phone_number',      '+21654421123',                                   'رقم الهاتف'),
  ('email',             'contact@estabrak.com',                           'البريد الإلكتروني'),
  ('address_fr',        'Houmt Souk, Djerba, Tunisie',                   'Adresse (FR)'),
  ('address_ar',        'حومة السوق، جربة، تونس',                         'العنوان (AR)'),
  ('instagram_url',     'https://www.instagram.com/estabrak',            'Instagram'),
  ('facebook_url',      'https://www.facebook.com/estabrak',             'Facebook'),
  ('tiktok_url',        'https://www.tiktok.com/@estabrak',              'TikTok'),
  ('youtube_url',       '',                                               'YouTube'),
  ('delivery_enabled',  'true',                                           'التوصيل مفعل'),
  ('cod_enabled',       'true',                                           'الدفع عند الاستلام'),
  ('delivery_cost_tn',  '7',                                              'تكلفة التوصيل داخل تونس (TND)'),
  ('delivery_cost_int', '25',                                             'تكلفة التوصيل الدولي (TND)'),
  ('currency',          'TND',                                            'العملة'),
  ('min_order',         '0',                                              'الحد الأدنى للطلب (TND)'),
  ('returns_days',      '14',                                             'أيام الإرجاع'),
  ('meta_desc_fr',      'ESTABRAK — Boutique premium hijabs, jilbabs, voiles et khimars. Élégance et pudeur. Livraison Tunisie et international.', 'Meta description FR'),
  ('meta_desc_ar',      'استبراك — بوتيك بريميوم للحجابات والجلابيب والخمارات. أناقة وحشمة. توصيل تونس والعالم.', 'Meta description AR');

-- ══════════════════════════════════════════════════════════════════════
--  PARTIE 7 : VÉRIFICATION FINALE
-- ══════════════════════════════════════════════════════════════════════

SELECT '══════════════════════════════════' AS separator;
SELECT 'ESTABRAK — Verification Base de Donnees' AS info;
SELECT '══════════════════════════════════' AS separator;

SELECT
  'categories'       AS table_name, COUNT(*) AS nb_rows FROM categories
UNION ALL SELECT 'products',             COUNT(*) FROM products
UNION ALL SELECT 'product_media',        COUNT(*) FROM product_media
UNION ALL SELECT 'reviews',              COUNT(*) FROM reviews
UNION ALL SELECT 'coupons',              COUNT(*) FROM coupons
UNION ALL SELECT 'site_settings',        COUNT(*) FROM site_settings
UNION ALL SELECT 'contact_messages',     COUNT(*) FROM contact_messages
UNION ALL SELECT 'orders',               COUNT(*) FROM orders
UNION ALL SELECT 'customers',            COUNT(*) FROM customers
ORDER BY table_name;

SELECT '' AS separator;
SELECT '✅ ESTABRAK Database configuree avec succes ! Hijab & Modest Elegance v3.0' AS status;

-- ══════════════════════════════════════════════════════════════════════
--  FIN DU FICHIER estabraq_supabase_seed.sql
--  © 2026 ESTABRAK — Hijab & Modest Elegance
--  contact@estabrak.com | WhatsApp: +216 54 421 123
-- ══════════════════════════════════════════════════════════════════════
