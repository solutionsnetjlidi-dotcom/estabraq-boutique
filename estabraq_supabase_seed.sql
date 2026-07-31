-- ══════════════════════════════════════════════════════════════════════
--  ESTABRAQ BOUTIQUE — Supabase Complete Schema + Seed Data
--  Boutique Luxe Djerba, Tunisie
--  Version 3.0 — 2026
--  Exécuter dans : Supabase → SQL Editor → Run
-- ══════════════════════════════════════════════════════════════════════

-- ── Extensions ───────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ══════════════════════════════════════════════════════════════════════
--  PARTIE 1 : CRÉATION DES TABLES
-- ══════════════════════════════════════════════════════════════════════

-- ── 1. Catégories ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name_ar     TEXT NOT NULL,
  name_fr     TEXT,
  name_en     TEXT,
  slug        TEXT UNIQUE NOT NULL,
  description TEXT,
  sort_order  INTEGER DEFAULT 0,
  is_active   BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. Produits ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id                  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  category_id         UUID REFERENCES categories(id) ON DELETE SET NULL,
  slug                TEXT UNIQUE NOT NULL,
  name_ar             TEXT NOT NULL,
  name_fr             TEXT,
  name_en             TEXT,
  description_ar      TEXT,
  description_fr      TEXT,
  description_en      TEXT,
  price               NUMERIC(10,3) NOT NULL DEFAULT 0,
  rent_price_per_day  NUMERIC(10,3),
  deposit_amount      NUMERIC(10,3),
  stock_quantity      INTEGER DEFAULT 0,
  sizes               TEXT[] DEFAULT '{}',
  colors              TEXT[] DEFAULT '{}',
  tags                TEXT[] DEFAULT '{}',
  is_active           BOOLEAN DEFAULT true,
  is_featured         BOOLEAN DEFAULT false,
  available_rent      BOOLEAN DEFAULT false,
  sort_order          INTEGER DEFAULT 0,
  meta_title          TEXT,
  meta_description    TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. Médias produits ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS product_media (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id   UUID REFERENCES products(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  alt_text     TEXT,
  is_primary   BOOLEAN DEFAULT false,
  sort_order   INTEGER DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── 4. Clients ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS customers (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name   TEXT NOT NULL,
  phone       TEXT,
  email       TEXT,
  city        TEXT,
  address     TEXT,
  wilaya      TEXT,
  country     TEXT DEFAULT 'TN',
  notes       TEXT,
  total_orders INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 5. Commandes ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id     UUID REFERENCES customers(id) ON DELETE SET NULL,
  status          TEXT DEFAULT 'pending'
                  CHECK (status IN ('pending','confirmed','shipped','delivered','cancelled','refunded')),
  payment_method  TEXT DEFAULT 'cod'
                  CHECK (payment_method IN ('cod','bank_transfer','paypal','card')),
  payment_status  TEXT DEFAULT 'pending'
                  CHECK (payment_status IN ('pending','paid','failed','refunded')),
  subtotal        NUMERIC(10,3) DEFAULT 0,
  discount_amount NUMERIC(10,3) DEFAULT 0,
  delivery_cost   NUMERIC(10,3) DEFAULT 7,
  total           NUMERIC(10,3) DEFAULT 0,
  coupon_code     TEXT,
  notes           TEXT,
  delivery_address TEXT,
  tracking_number TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── 6. Articles de commande ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_items (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id    UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id  UUID REFERENCES products(id) ON DELETE SET NULL,
  quantity    INTEGER DEFAULT 1,
  unit_price  NUMERIC(10,3) NOT NULL,
  size        TEXT,
  color       TEXT,
  subtotal    NUMERIC(10,3) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 7. Locations / Rentals ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rentals (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id      UUID REFERENCES products(id) ON DELETE SET NULL,
  order_id        UUID REFERENCES orders(id) ON DELETE SET NULL,
  customer_id     UUID REFERENCES customers(id) ON DELETE SET NULL,
  status          TEXT DEFAULT 'pending'
                  CHECK (status IN ('pending','active','returned','cancelled','overdue')),
  start_date      DATE,
  end_date        DATE,
  daily_rate      NUMERIC(10,3) DEFAULT 0,
  deposit_paid    NUMERIC(10,3) DEFAULT 0,
  deposit_returned BOOLEAN DEFAULT false,
  total_days      INTEGER GENERATED ALWAYS AS (
                    CASE WHEN end_date IS NOT NULL AND start_date IS NOT NULL
                    THEN (end_date - start_date) ELSE 0 END
                  ) STORED,
  size            TEXT,
  color           TEXT,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── 8. Avis clients ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id     UUID REFERENCES products(id) ON DELETE CASCADE,
  order_id       UUID REFERENCES orders(id) ON DELETE SET NULL,
  reviewer_name  TEXT NOT NULL,
  reviewer_email TEXT,
  reviewer_flag  TEXT DEFAULT '🇹🇳',
  reviewer_location TEXT,
  rating         INTEGER DEFAULT 5 CHECK (rating BETWEEN 1 AND 5),
  comment_ar     TEXT,
  comment_fr     TEXT,
  comment_en     TEXT,
  is_approved    BOOLEAN DEFAULT false,
  is_featured    BOOLEAN DEFAULT false,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ── 9. Coupons de réduction ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS coupons (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code            TEXT UNIQUE NOT NULL,
  description     TEXT,
  discount_type   TEXT DEFAULT 'percentage'
                  CHECK (discount_type IN ('percentage','fixed')),
  discount_value  NUMERIC(10,3) NOT NULL,
  min_purchase    NUMERIC(10,3) DEFAULT 0,
  max_uses        INTEGER,
  current_uses    INTEGER DEFAULT 0,
  is_active       BOOLEAN DEFAULT true,
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── 10. Messages contact ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS contact_messages (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name        TEXT NOT NULL,
  email       TEXT,
  phone       TEXT,
  subject     TEXT,
  message     TEXT NOT NULL,
  lang        TEXT DEFAULT 'ar',
  is_read     BOOLEAN DEFAULT false,
  replied_at  TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 11. Paramètres du site ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS site_settings (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key        TEXT UNIQUE NOT NULL,
  value      TEXT,
  label      TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── 12. Notifications admin ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_notifications (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type       TEXT NOT NULL,
  title      TEXT,
  message    TEXT,
  is_read    BOOLEAN DEFAULT false,
  data       JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════════════
--  PARTIE 2 : INDEX (performances)
-- ══════════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_products_category    ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_active      ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_featured    ON products(is_featured);
CREATE INDEX IF NOT EXISTS idx_products_slug        ON products(slug);
CREATE INDEX IF NOT EXISTS idx_product_media_prod   ON product_media(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer      ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status        ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created       ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_order    ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_rentals_product      ON rentals(product_id);
CREATE INDEX IF NOT EXISTS idx_rentals_status       ON rentals(status);
CREATE INDEX IF NOT EXISTS idx_reviews_product      ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_approved     ON reviews(is_approved);
CREATE INDEX IF NOT EXISTS idx_coupons_code         ON coupons(code);
CREATE INDEX IF NOT EXISTS idx_settings_key         ON site_settings(key);

-- ══════════════════════════════════════════════════════════════════════
--  PARTIE 3 : TRIGGERS (mise à jour automatique)
-- ══════════════════════════════════════════════════════════════════════

-- Trigger updated_at automatique
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_products_updated
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_orders_updated
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_rentals_updated
  BEFORE UPDATE ON rentals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_customers_updated
  BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════════════════
--  PARTIE 4 : RLS POLICIES (Sécurité)
-- ══════════════════════════════════════════════════════════════════════

-- Activer RLS sur toutes les tables
ALTER TABLE categories       ENABLE ROW LEVEL SECURITY;
ALTER TABLE products         ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_media    ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers        ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders           ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items      ENABLE ROW LEVEL SECURITY;
ALTER TABLE rentals          ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews          ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons          ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_settings    ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons          ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques (évite les conflits)
DROP POLICY IF EXISTS "Public products read"        ON products;
DROP POLICY IF EXISTS "Public categories read"      ON categories;
DROP POLICY IF EXISTS "Public reviews read"         ON reviews;
DROP POLICY IF EXISTS "Public settings read"        ON site_settings;
DROP POLICY IF EXISTS "Public media read"           ON product_media;
DROP POLICY IF EXISTS "Public insert customers"     ON customers;
DROP POLICY IF EXISTS "Public insert orders"        ON orders;
DROP POLICY IF EXISTS "Public insert order_items"   ON order_items;
DROP POLICY IF EXISTS "Public insert rentals"       ON rentals;
DROP POLICY IF EXISTS "Public insert contact"       ON contact_messages;
DROP POLICY IF EXISTS "Public coupons check"        ON coupons;
DROP POLICY IF EXISTS "Admin all products"          ON products;
DROP POLICY IF EXISTS "Admin all orders"            ON orders;
DROP POLICY IF EXISTS "Admin all customers"         ON customers;
DROP POLICY IF EXISTS "Admin all reviews"           ON reviews;
DROP POLICY IF EXISTS "Admin all settings"          ON site_settings;
DROP POLICY IF EXISTS "Admin all rentals"           ON rentals;
DROP POLICY IF EXISTS "Admin all contact"           ON contact_messages;
DROP POLICY IF EXISTS "Admin all media"             ON product_media;
DROP POLICY IF EXISTS "Admin all categories"        ON categories;
DROP POLICY IF EXISTS "Admin all notifications"     ON admin_notifications;
DROP POLICY IF EXISTS "Admin all coupons"           ON coupons;

-- ── Lecture publique ──────────────────────────────────────────────────
CREATE POLICY "Public products read"
  ON products FOR SELECT USING (is_active = true);

CREATE POLICY "Public categories read"
  ON categories FOR SELECT USING (is_active = true);

CREATE POLICY "Public reviews read"
  ON reviews FOR SELECT USING (is_approved = true);

CREATE POLICY "Public settings read"
  ON site_settings FOR SELECT USING (true);

CREATE POLICY "Public media read"
  ON product_media FOR SELECT USING (true);

-- ── Insertion publique (clients du frontend) ──────────────────────────
CREATE POLICY "Public insert customers"
  ON customers FOR INSERT WITH CHECK (true);

CREATE POLICY "Public insert orders"
  ON orders FOR INSERT WITH CHECK (true);

CREATE POLICY "Public insert order_items"
  ON order_items FOR INSERT WITH CHECK (true);

CREATE POLICY "Public insert rentals"
  ON rentals FOR INSERT WITH CHECK (true);

CREATE POLICY "Public insert contact"
  ON contact_messages FOR INSERT WITH CHECK (true);

CREATE POLICY "Public insert reviews"
  ON reviews FOR INSERT WITH CHECK (true);

CREATE POLICY "Public coupons check"
  ON coupons FOR SELECT USING (is_active = true);

-- ── Accès admin complet (via anon key) ───────────────────────────────
CREATE POLICY "Admin all products"
  ON products FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Admin all orders"
  ON orders FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Admin all customers"
  ON customers FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Admin all reviews"
  ON reviews FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Admin all settings"
  ON site_settings FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Admin all rentals"
  ON rentals FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Admin all contact"
  ON contact_messages FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Admin all media"
  ON product_media FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Admin all categories"
  ON categories FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Admin all notifications"
  ON admin_notifications FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Admin all coupons"
  ON coupons FOR ALL USING (true) WITH CHECK (true);

-- ══════════════════════════════════════════════════════════════════════
--  PARTIE 5 : DONNÉES INITIALES (SEED)
-- ══════════════════════════════════════════════════════════════════════

-- ── Catégories ────────────────────────────────────────────────────────
INSERT INTO categories (name_ar, name_fr, name_en, slug, sort_order)
VALUES
  ('قفاطين',  'Caftans',          'Caftans',          'caftans',  1),
  ('فساتين',  'Robes de Soirée',  'Evening Dresses',  'dresses',  2),
  ('عروس',    'Mariage',          'Wedding',          'wedding',  3),
  ('إيجار',   'Location',         'Rental',           'rental',   4)
ON CONFLICT (slug) DO NOTHING;

-- ── Paramètres du site ────────────────────────────────────────────────
INSERT INTO site_settings (key, value, label) VALUES
  ('whatsapp_number',   '+21654421123',                        'رقم واتساب'),
  ('phone_number',      '+21654421123',                        'رقم الهاتف'),
  ('email',             'contact@estabraq-boutique.tn',        'البريد الإلكتروني'),
  ('address_ar',        'شارع الحبيب بورقيبة، حومة السوق، جربة', 'العنوان (عربي)'),
  ('address_fr',        'Avenue Habib Bourguiba, Houmt Souk, Djerba', 'Adresse (français)'),
  ('instagram_url',     'https://www.instagram.com/estabraq_djerba', 'Instagram'),
  ('facebook_url',      'https://www.facebook.com/estabraq.djerba',  'Facebook'),
  ('tiktok_url',        'https://www.tiktok.com/@estabraq',          'TikTok'),
  ('delivery_enabled',  'true',   'خدمة التوصيل'),
  ('cod_enabled',       'true',   'الدفع عند الاستلام'),
  ('delivery_cost',     '7',      'تكلفة التوصيل (د.ت)'),
  ('currency',          'TND',    'العملة'),
  ('site_name_ar',      'استبرق | ESTABRAQ', 'اسم الموقع (عربي)'),
  ('site_name_fr',      'ESTABRAQ Boutique', 'Nom du site (français)'),
  ('meta_description',  'بوتيك الأزياء الفاخرة بجربة تونس — فساتين وقفاطين مطرزة يدوياً للبيع والإيجار', 'وصف SEO')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- ── Produits (12 produits avec images Unsplash) ───────────────────────

-- Caftans
WITH cat AS (SELECT id FROM categories WHERE slug = 'caftans' LIMIT 1)
INSERT INTO products
  (category_id, slug, name_ar, name_fr, name_en,
   description_ar, description_fr,
   price, rent_price_per_day, deposit_amount,
   stock_quantity, sizes, colors, tags,
   is_active, is_featured, available_rent)
SELECT
  cat.id,
  slug, name_ar, name_fr, name_en,
  description_ar, description_fr,
  price, rent_price_per_day, deposit_amount,
  stock_quantity, sizes, colors, tags,
  true, is_featured, available_rent
FROM cat, (VALUES
  (
    'caftan-marocain-royal-or',
    'قفطان مغربي ملكي ذهبي',
    'Caftan Marocain Royal Doré',
    'Royal Golden Moroccan Caftan',
    'قفطان مغربي أصيل مطرز يدوياً بخيوط الذهب الحقيقي على قماش حرير طبيعي فاخر. مثالي لليالي الكبرى والمناسبات الاستثنائية.',
    'Caftan marocain authentique brodé à la main avec des fils d''or sur soie naturelle luxueuse. Idéal pour les grandes occasions.',
    2200.000, 280.000, 500.000, 3,
    ARRAY['S','M','L','XL'],
    ARRAY['ذهبي','عاجي','شمبانيا'],
    ARRAY['featured','vip','new'],
    true, true
  ),
  (
    'caftan-soiree-brode-bleu',
    'قفطان سهرة مطرز أزرق',
    'Caftan Soirée Brodé Bleu Royal',
    'Royal Blue Embroidered Caftan',
    'قفطان سهرة فاخر باللون الأزرق الملكي مع تطريزات فضية دقيقة تغطي أطراف الأكمام والجيب.',
    'Caftan de soirée luxueux en bleu royal avec des broderies argentées délicates sur les manches et le décolleté.',
    1100.000, 150.000, 250.000, 5,
    ARRAY['S','M','L','XL','XXL'],
    ARRAY['أزرق ملكي','أزرق سماوي','فضي'],
    ARRAY['featured','bestseller'],
    true, true
  ),
  (
    'caftan-quotidien-vert-olive',
    'قفطان يومي أخضر زيتوني',
    'Caftan Quotidien Vert Olive',
    'Olive Green Daily Caftan',
    'قفطان يومي أنيق ومريح باللون الأخضر الزيتوني، مثالي للمناسبات اليومية والنزهات العائلية.',
    'Caftan quotidien élégant et confortable en vert olive, parfait pour les occasions décontractées.',
    320.000, 45.000, 100.000, 10,
    ARRAY['S','M','L','XL'],
    ARRAY['أخضر زيتوني','بني','بيج'],
    ARRAY['new'],
    true, false
  ),
  (
    'caftan-mariage-blanc-perle',
    'قفطان زفاف أبيض لؤلؤي',
    'Caftan Mariage Blanc Perle',
    'Pearl White Wedding Caftan',
    'قفطان زفاف فاخر باللون الأبيض اللؤلؤي مع تطريزات ذهبية كثيفة وحجر كريم لامع. قطعة استثنائية لليلة لا تُنسى.',
    'Caftan de mariage luxueux blanc perle avec broderies dorées intenses et pierres précieuses. Une pièce exceptionnelle pour une nuit inoubliable.',
    3500.000, 450.000, 800.000, 2,
    ARRAY['S','M','L','XL'],
    ARRAY['أبيض لؤلؤي','ذهبي'],
    ARRAY['vip','featured','wedding'],
    true, true
  ),
  (
    'caftan-moderne-rose-gold',
    'قفطان عصري وردي ذهبي',
    'Caftan Moderne Rose Gold',
    'Modern Rose Gold Caftan',
    'قفطان عصري بتصميم معاصر يجمع بين اللون الوردي الفاخر واللمسات الذهبية البراقة.',
    'Caftan moderne au design contemporain alliant rose luxueux et touches dorées scintillantes.',
    650.000, 90.000, 150.000, 7,
    ARRAY['XS','S','M','L'],
    ARRAY['وردي ذهبي','وردي عاجي','ذهبي'],
    ARRAY['new','bestseller'],
    true, true
  ),
  (
    'caftan-soiree-bordeaux',
    'قفطان سهرة بوردو فاخر',
    'Caftan Soirée Bordeaux Luxe',
    'Luxury Bordeaux Evening Caftan',
    'قفطان سهرة بلون البوردو الداكن الفاخر مع تطريزات ذهبية على الرقبة والأكمام.',
    'Caftan de soirée bordeaux foncé luxueux avec broderies dorées sur le col et les manches.',
    880.000, 120.000, 200.000, 4,
    ARRAY['S','M','L','XL'],
    ARRAY['بوردو','برغندي','ذهبي'],
    ARRAY['featured'],
    true, true
  )
) AS p(slug, name_ar, name_fr, name_en, description_ar, description_fr,
       price, rent_price_per_day, deposit_amount, stock_quantity,
       sizes, colors, tags, is_featured, available_rent)
ON CONFLICT (slug) DO NOTHING;

-- Robes de Soirée (Fassatin)
WITH cat AS (SELECT id FROM categories WHERE slug = 'dresses' LIMIT 1)
INSERT INTO products
  (category_id, slug, name_ar, name_fr, name_en,
   description_ar, description_fr,
   price, rent_price_per_day, deposit_amount,
   stock_quantity, sizes, colors, tags,
   is_active, is_featured, available_rent)
SELECT
  cat.id,
  slug, name_ar, name_fr, name_en,
  description_ar, description_fr,
  price, rent_price_per_day, deposit_amount,
  stock_quantity, sizes, colors, tags,
  true, is_featured, available_rent
FROM cat, (VALUES
  (
    'robe-soiree-noir-classique',
    'فستان سهرة أسود كلاسيكي',
    'Robe de Soirée Noire Classique',
    'Classic Black Evening Dress',
    'فستان سهرة أسود كلاسيكي بتصميم أنيق ومحكم يبرز الأناقة الحقيقية. مصنوع من الساتان الفاخر مع تفاصيل مطرزة.',
    'Robe de soirée noire classique au design élégant. Confectionnée en satin luxueux avec des détails brodés.',
    780.000, 110.000, 200.000, 6,
    ARRAY['XS','S','M','L','XL'],
    ARRAY['أسود'],
    ARRAY['bestseller','featured'],
    true, true
  ),
  (
    'robe-cocktail-rouge-passion',
    'فستان كوكتيل أحمر قاني',
    'Robe Cocktail Rouge Passion',
    'Passion Red Cocktail Dress',
    'فستان كوكتيل أحمر جريء وجذاب، مثالي لحفلات الكوكتيل والمناسبات الراقية. تصميم عصري بأكمام شفافة.',
    'Robe cocktail rouge audacieuse et attrayante, idéale pour les cocktails et les soirées raffinées.',
    540.000, 75.000, 150.000, 8,
    ARRAY['XS','S','M','L'],
    ARRAY['أحمر','نبيذي'],
    ARRAY['new','bestseller'],
    true, false
  ),
  (
    'robe-mariage-princesse-blanche',
    'فستان زفاف الأميرة الأبيض',
    'Robe de Mariée Princesse Blanche',
    'White Princess Wedding Dress',
    'فستان زفاف أبيض فاخر بتصميم الأميرة مع تنورة واسعة وذيل طويل. مزين بالدانتيل الفرنسي والخرز الكريستالي.',
    'Robe de mariée blanche luxueuse au style princesse avec une jupe volumineuse et une longue traîne. Ornée de dentelle française et de perles cristal.',
    4200.000, 550.000, 1000.000, 1,
    ARRAY['S','M','L'],
    ARRAY['أبيض','عاجي'],
    ARRAY['vip','wedding','featured'],
    true, true
  ),
  (
    'robe-soiree-doree-brillante',
    'فستان سهرة ذهبي لامع',
    'Robe de Soirée Dorée Scintillante',
    'Shimmering Gold Evening Dress',
    'فستان سهرة ذهبي لامع بمقاسات دقيقة، مثالي للحفلات الراقية. يبرز الأنوثة بأبهى تجلياتها.',
    'Robe de soirée dorée scintillante aux coupes précises, parfaite pour les galas et soirées de prestige.',
    1250.000, 165.000, 300.000, 4,
    ARRAY['S','M','L'],
    ARRAY['ذهبي','برونزي','شمبانيا'],
    ARRAY['featured','bestseller'],
    true, true
  ),
  (
    'robe-soiree-bleu-royal',
    'فستان سهرة أزرق ملكي',
    'Robe de Soirée Bleu Royal',
    'Royal Blue Evening Dress',
    'فستان سهرة بالأزرق الملكي العميق، يجمع بين الفخامة والأناقة مع تفاصيل مطرزة تلتقط الضوء.',
    'Robe de soirée bleu royal profond, alliant luxe et élégance avec des détails brodés qui capturent la lumière.',
    920.000, 130.000, 220.000, 5,
    ARRAY['S','M','L','XL'],
    ARRAY['أزرق ملكي','أزرق نيلي','أسود'],
    ARRAY['new'],
    true, true
  ),
  (
    'robe-cocktail-rose-chic',
    'فستان كوكتيل وردي شيك',
    'Robe Cocktail Rose Chic',
    'Chic Pink Cocktail Dress',
    'فستان كوكتيل وردي ناعم بتصميم شيك عصري، يمنحك إطلالة أنثوية راقية في كل المناسبات.',
    'Robe cocktail rose tendre au design chic contemporain, pour une allure féminine raffinée en toutes occasions.',
    420.000, 60.000, 100.000, 9,
    ARRAY['XS','S','M'],
    ARRAY['وردي','وردي فاتح','أبيض وردي'],
    ARRAY['new'],
    true, false
  )
) AS p(slug, name_ar, name_fr, name_en, description_ar, description_fr,
       price, rent_price_per_day, deposit_amount, stock_quantity,
       sizes, colors, tags, is_featured, available_rent)
ON CONFLICT (slug) DO NOTHING;

-- ── Médias produits (images Unsplash) ────────────────────────────────
INSERT INTO product_media (product_id, storage_path, alt_text, is_primary, sort_order)
SELECT p.id,
  CASE p.slug
    WHEN 'caftan-marocain-royal-or'       THEN 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=800&h=1067&fit=crop'
    WHEN 'caftan-soiree-brode-bleu'       THEN 'https://images.unsplash.com/photo-1594552072238-b8a33785b261?w=800&h=1067&fit=crop'
    WHEN 'caftan-quotidien-vert-olive'    THEN 'https://images.unsplash.com/photo-1585487000160-6ebcfceb0d03?w=800&h=1067&fit=crop'
    WHEN 'caftan-mariage-blanc-perle'     THEN 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=800&h=1067&fit=crop'
    WHEN 'caftan-moderne-rose-gold'       THEN 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800&h=1067&fit=crop'
    WHEN 'caftan-soiree-bordeaux'         THEN 'https://images.unsplash.com/photo-1544022613-e87ca75a784a?w=800&h=1067&fit=crop'
    WHEN 'robe-soiree-noir-classique'     THEN 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=800&h=1067&fit=crop'
    WHEN 'robe-cocktail-rouge-passion'    THEN 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=800&h=1067&fit=crop'
    WHEN 'robe-mariage-princesse-blanche' THEN 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&h=1067&fit=crop'
    WHEN 'robe-soiree-doree-brillante'    THEN 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800&h=1067&fit=crop'
    WHEN 'robe-soiree-bleu-royal'         THEN 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=800&h=1067&fit=crop&hue=240'
    WHEN 'robe-cocktail-rose-chic'        THEN 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800&h=1067&fit=crop&hue=300'
    ELSE 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=800&h=1067&fit=crop'
  END,
  p.name_ar || ' — استبرق جربة تونس',
  true,
  0
FROM products p
WHERE NOT EXISTS (
  SELECT 1 FROM product_media pm WHERE pm.product_id = p.id AND pm.is_primary = true
);

-- ── Avis clients initiaux ─────────────────────────────────────────────
INSERT INTO reviews
  (reviewer_name, reviewer_flag, reviewer_location, rating,
   comment_ar, comment_fr, is_approved, is_featured)
VALUES
  ('سارة البوعزيزي',   '🇹🇳', 'تونس العاصمة', 5,
   'تجربة رائعة! القفطان أجمل بكثير من الصور. الجودة فاخرة جداً والخياطة محكمة. التوصيل كان سريعاً والدفع عند الاستلام كان مريحاً جداً.',
   'Expérience magnifique! Le caftan est bien plus beau qu''en photo. Qualité très luxueuse, livraison rapide et paiement à la livraison très pratique.',
   true, true),

  ('منيرة العلوي',     '🇲🇦', 'كازابلانكا، المغرب', 5,
   'أفضل بوتيك للقفاطين تعاملت معه. فستان الزفاف تجاوز كل توقعاتي! الخدمة ممتازة والفريق محترف جداً.',
   'La meilleure boutique de caftans avec laquelle j''ai traité. La robe de mariée a dépassé toutes mes attentes! Service excellent et équipe très professionnelle.',
   true, true),

  ('Amira Trabelsi',   '🇫🇷', 'Paris, France', 5,
   'قفطان استثنائي، خدمة ممتازة!',
   'Caftan exceptionnel reçu à Paris sans problème! Service client impeccable et paiement sécurisé. Je recommande vivement Estabraq pour leur savoir-faire artisanal.',
   true, true),

  ('رانيا قاسم',        '🇹🇳', 'صفاقس', 5,
   'اشتريت قفطاناً للعيد والجودة فاخرة جداً. التطريز اليدوي رائع والألوان تماماً كما في الصور. شكراً جزيلاً لفريق استبرق!',
   'J''ai acheté un caftan pour l''Aïd et la qualité est vraiment luxueuse. La broderie manuelle est magnifique. Merci à l''équipe d''Estabraq!',
   true, false),

  ('Leila Ben Salah',  '🇹🇳', 'Sousse', 5,
   'زيارة رائعة لبوتيك استبرق في جربة',
   'Visitée lors d''un séjour à Djerba, la boutique Estabraq est une référence! Large gamme de robes et caftans, prix compétitifs et équipe très accueillante.',
   true, false),

  ('خلود محمود',        '🇩🇿', 'الجزائر العاصمة', 4,
   'كجزائرية، سعيدة جداً بتجربة الشراء من استبرق. القفاطين رائعة وأسعارها ممتازة مقارنة بالسوق المغربي. أنصح به بشدة!',
   'En tant qu''Algérienne, très satisfaite de mon achat chez Estabraq. Les caftans sont magnifiques et les prix excellents. Je recommande vivement!',
   true, false),

  ('ياسمين الزهراني',  '🇸🇦', 'جدة، السعودية', 5,
   'طلبت قفطاناً للحفل وصلني في أحسن حال. الجودة تفوق ما توقعته. استبرق بوتيك راقٍ بحق، سأعود للطلب مرة أخرى.',
   'J''ai commandé un caftan pour une cérémonie, reçu en parfait état. Qualité au-delà de mes attentes. Estabraq est vraiment une boutique de prestige.',
   true, true),

  ('Fatma Ayari',      '🇩🇪', 'Berlin, Allemagne', 5,
   'أهدت لي صديقة تونسية رابط استبرق',
   'Une amie tunisienne m''a recommandé Estabraq et je ne suis pas déçue! La robe de soirée est absolument sublime. Livraison internationale parfaite.',
   true, false)
ON CONFLICT DO NOTHING;

-- ── Coupons de bienvenue ──────────────────────────────────────────────
INSERT INTO coupons (code, description, discount_type, discount_value, min_purchase, max_uses, is_active)
VALUES
  ('ESTABRAQ10',  'خصم 10% على أول طلب',           'percentage', 10,  200, 100, true),
  ('WELCOME20',   'خصم 20% للعملاء الجدد',          'percentage', 20,  500, 50,  true),
  ('DJERBA50',    'خصم 50 دينار على الطلبات الكبيرة','fixed',       50, 1000, 200, true),
  ('EID2026',     'خصم العيد 15%',                  'percentage', 15,  300, 500, true),
  ('VIP30',       'خصم VIP 30%',                   'percentage', 30, 1500, 20,  true)
ON CONFLICT (code) DO NOTHING;

-- ══════════════════════════════════════════════════════════════════════
--  PARTIE 6 : VÉRIFICATION FINALE
-- ══════════════════════════════════════════════════════════════════════

SELECT '══ VÉRIFICATION ESTABRAQ DATABASE ══' AS info;

SELECT
  'categories'       AS table_name, COUNT(*) AS rows FROM categories
UNION ALL SELECT
  'products',                        COUNT(*) FROM products
UNION ALL SELECT
  'product_media',                   COUNT(*) FROM product_media
UNION ALL SELECT
  'reviews',                         COUNT(*) FROM reviews
UNION ALL SELECT
  'coupons',                         COUNT(*) FROM coupons
UNION ALL SELECT
  'site_settings',                   COUNT(*) FROM site_settings
UNION ALL SELECT
  'contact_messages',                COUNT(*) FROM contact_messages
ORDER BY table_name;

SELECT '✅ Base de données ESTABRAQ configurée avec succès!' AS status;
