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

-- ── Colonnes de compatibilité (utilisées par admin.html et le frontend) ──
-- Le frontend/admin pilotent les produits via une colonne "category" (texte simple)
-- et une colonne "badge" (texte), en plus de la structure category_id/tags existante.
ALTER TABLE products ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS badge    TEXT;
CREATE INDEX IF NOT EXISTS idx_products_category_txt ON products(category);

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

-- ── Nettoyage de l'ancien catalogue (caftans / robes de soirée) ────────
-- On repart sur une vitrine organisée : Hijab · Jilbab · Accessoires Islamiques · Tapis de Prière
DELETE FROM product_media WHERE product_id IN (
  SELECT id FROM products WHERE slug LIKE 'caftan-%' OR slug LIKE 'robe-%'
);
DELETE FROM products WHERE slug LIKE 'caftan-%' OR slug LIKE 'robe-%';
DELETE FROM categories WHERE slug IN ('caftans','dresses','wedding','rental');

-- ── Catégories (4 collections) ──────────────────────────────────────────
INSERT INTO categories (name_ar, name_fr, name_en, slug, description, sort_order)
VALUES
  ('حجاب',              'Hijab',                      'Hijab',                'hijab',       'Hijabs, voiles et khimars premium',            1),
  ('جلباب',             'Jilbab',                      'Jilbab',               'jilbab',      'Jilbabs élégants pour toutes occasions',        2),
  ('إكسسوارات إسلامية', 'Accessoires Islamiques Femme','Islamic Accessories',  'accessoire',  'Épingles, bonnets, ceintures et broches',        3),
  ('سجادة الصلاة',      'Tapis de Prière',             'Prayer Rugs',          'tapis',       'Tapis de prière brodés et sets cadeaux',         4)
ON CONFLICT (slug) DO NOTHING;

-- ── Paramètres du site ────────────────────────────────────────────────
INSERT INTO site_settings (key, value, label) VALUES
  ('whatsapp_number',   '+21654421123',                        'رقم واتساب'),
  ('phone_number',      '+21654421123',                        'رقم الهاتف'),
  ('email',             'contact@estabrak.com',                'البريد الإلكتروني'),
  ('address_ar',        'شارع الحبيب بورقيبة، ميدون، جربة',      'العنوان (عربي)'),
  ('address_fr',        'Avenue Habib Bourguiba, Midoun, Djerba','Adresse (français)'),
  ('instagram_url',     'https://www.instagram.com/estabrak_djerba', 'Instagram'),
  ('facebook_url',      'https://www.facebook.com/estabrak.djerba',  'Facebook'),
  ('tiktok_url',        'https://www.tiktok.com/@estabrak',          'TikTok'),
  ('delivery_enabled',  'true',   'خدمة التوصيل'),
  ('cod_enabled',       'true',   'الدفع عند الاستلام'),
  ('delivery_cost',     '7',      'تكلفة التوصيل (د.ت)'),
  ('currency',          'TND',    'العملة'),
  ('site_name_ar',      'استبرق | ESTABRAK', 'اسم الموقع (عربي)'),
  ('site_name_fr',      'ESTABRAK Boutique', 'Nom du site (français)'),
  ('meta_description',  'بوتيك الحشمة الراقي بجربة تونس — حجابات، جلابيب، إكسسوارات إسلامية وسجاد صلاة فاخر', 'وصف SEO')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- ── Produits (18 produits — 4 collections, images Unsplash) ────────────
-- category : 'hijab' | 'jilbab' | 'accessoire' | 'tapis'  (colonne texte pilotée par admin.html / frontend)
INSERT INTO products
  (slug, name_ar, name_fr, name_en, description_ar, description_fr,
   category, price, rent_price_per_day, deposit_amount, stock_quantity,
   sizes, colors, tags, badge, is_active, is_featured, available_rent)
VALUES
  -- ═══ COLLECTION HIJAB ═══
  ('hijab-mousseline-premium-ivoire',
   'حجاب موسلين بريميوم', 'Hijab Mousseline Premium', 'Premium Chiffon Hijab',
   'حجاب بريميوم من الموسلين، خفيف وسلس وغير شفاف. سقوط مثالي على الكتفين.',
   'Notre hijab signature en mousseline premium. Léger, fluide et antitransparence. Tombe parfaitement.',
   'hijab', 85.000, NULL, NULL, 40,
   ARRAY['Taille Unique'], ARRAY['Noir','Ivoire','Beige','Taupe','Camel'], ARRAY['new'], 'new',
   true, true, false),

  ('hijab-soie-medine-luxe',
   'حجاب حرير المدينة', 'Hijab Soie de Médine', 'Medina Silk Hijab',
   'حجاب من حرير المدينة بنعومة استثنائية. مثالي للمناسبات الخاصة.',
   'Un voile en soie de Médine d''une douceur incomparable. Idéal pour les occasions spéciales.',
   'hijab', 120.000, NULL, NULL, 25,
   ARRAY['Taille Unique'], ARRAY['Noir','Bordeaux','Bleu Nuit','Champagne'], ARRAY['bestseller'], 'best',
   true, true, false),

  ('hijab-jersey-modal-doux',
   'حجاب جيرسي مودال ناعم', 'Hijab Jersey Modal Doux', 'Soft Modal Jersey Hijab',
   'حجاب اليوميات بامتياز. جيرسي مودال فائق النعومة لتصفيف سهل وأنيق.',
   'Le hijab du quotidien par excellence. Jersey modal ultra-doux pour une coiffure facile et élégante.',
   'hijab', 65.000, NULL, NULL, 60,
   ARRAY['Taille Unique'], ARRAY['Noir','Beige','Taupe','Sauge','Rose Poudré'], ARRAY[]::text[], NULL,
   true, false, false),

  ('hijab-crepe-signature',
   'حجاب كريب سيغنتشر', 'Hijab Crêpe Signature', 'Signature Crepe Hijab',
   'حجابنا المميز من الكريب. مقاوم للتجعد بشكل طبيعي، مثالي للمرأة النشيطة.',
   'Notre hijab crêpe signature. Anti-froissage naturel, parfait pour les femmes actives.',
   'hijab', 110.000, NULL, NULL, 20,
   ARRAY['Taille Unique'], ARRAY['Noir','Bordeaux','Champagne','Chocolat'], ARRAY['limited'], 'limited',
   true, false, false),

  ('voile-chiffon-delicat',
   'طرحة شيفون رقيقة', 'Voile Chiffon Délicat', 'Delicate Chiffon Veil',
   'طرحة من الشيفون بخفة استثنائية. للمناسبات الخاصة والاحتفالات.',
   'Voile en chiffon d''une légèreté exquise. Pour les occasions spéciales et les cérémonies.',
   'hijab', 95.000, NULL, NULL, 22,
   ARRAY['Taille Unique'], ARRAY['Ivoire','Rose Poudré','Sauge','Champagne'], ARRAY['new','voile'], 'new',
   true, false, false),

  ('voile-nidha-prestige',
   'طرحة نيضة بريستيج', 'Voile Nidha Prestige', 'Prestige Nidha Veil',
   'طرحة من قماش النيضة الفاخر. سقوط مثالي، غير شفافة وخفيفة. للمناسبات الكبرى.',
   'Voile en Nidha de prestige. Tombé parfait, opaque et léger. Pour les grandes occasions.',
   'hijab', 145.000, NULL, NULL, 15,
   ARRAY['Taille Unique'], ARRAY['Noir','Ivoire','Bordeaux','Bleu Nuit'], ARRAY['limited','voile'], 'limited',
   true, true, false),

  ('khimar-long-premium',
   'خمار طويل بريميوم', 'Khimar Long Premium', 'Premium Long Khimar',
   'خمار طويل من الجيرسي الفاخر يغطي الصدر. راحة تامة للارتداء اليومي.',
   'Khimar long en jersey premium. Couvre le buste. Confort total pour un port quotidien.',
   'hijab', 150.000, NULL, NULL, 18,
   ARRAY['S/M','L/XL'], ARRAY['Noir','Chocolat','Bordeaux','Olive'], ARRAY['new','khimar'], 'new',
   true, false, false),

  ('khimar-court-quotidien',
   'خمار قصير يومي', 'Khimar Court Quotidien', 'Everyday Short Khimar',
   'خمار قصير عملي للارتداء اليومي. جيرسي بريميوم مطاطي وثبات ممتاز.',
   'Khimar court pratique pour le quotidien. Jersey premium stretch, maintien excellent.',
   'hijab', 95.000, NULL, NULL, 30,
   ARRAY['Taille Unique'], ARRAY['Noir','Moka','Olive','Sauge'], ARRAY['khimar'], NULL,
   true, false, false),

  -- ═══ COLLECTION JILBAB ═══
  ('jilbab-classique-elegant',
   'جلباب كلاسيكي أنيق', 'Jilbab Classique Élégant', 'Classic Elegant Jilbab',
   'جلباب بقصات منسابة يجمع بين الأصالة والمعاصرة. قماش مقاوم للتجعد بجودة عالية.',
   'Jilbab aux coupes fluides qui allient tradition et modernité. Tissu anti-froissage de qualité supérieure.',
   'jilbab', 195.000, 25.000, 80.000, 12,
   ARRAY['S','M','L','XL','XXL'], ARRAY['Noir','Moka','Bleu Nuit'], ARRAY['bestseller'], 'best',
   true, true, true),

  ('jilbab-boutonne-moderne',
   'جلباب بأزرار عصري', 'Jilbab Boutonné Moderne', 'Modern Buttoned Jilbab',
   'جلباب بأزرار بطابع عصري. قصة موسعة قليلاً، مثالية للمدينة.',
   'Jilbab boutonné au style contemporain. Coupe légèrement évasée, parfaite pour la ville.',
   'jilbab', 220.000, NULL, NULL, 10,
   ARRAY['S','M','L','XL'], ARRAY['Noir','Moka','Camel','Gris Perle'], ARRAY[]::text[], NULL,
   true, true, false),

  ('jilbab-brode-ceremonie',
   'جلباب مطرز للمناسبات', 'Jilbab Brodé Cérémonie', 'Embroidered Ceremony Jilbab',
   'جلباب مطرز فاخر للمناسبات الكبرى، الأعياد والأفراح. تفاصيل مطرزة يدوياً على الأكمام والياقة.',
   'Jilbab brodé de prestige pour l''Aïd et les grandes occasions. Broderies délicates faites main sur manches et col.',
   'jilbab', 320.000, 45.000, 150.000, 6,
   ARRAY['S','M','L','XL'], ARRAY['Noir','Émeraude','Bordeaux'], ARRAY['limited','vip'], 'limited',
   true, true, true),

  ('jilbab-quotidien-confort',
   'جلباب يومي مريح', 'Jilbab Quotidien Confort', 'Everyday Comfort Jilbab',
   'جلباب يومي بسيط ومريح، قماش ناعم يسمح بالحركة بكل يسر طوال اليوم.',
   'Jilbab quotidien simple et confortable, tissu doux permettant une liberté de mouvement toute la journée.',
   'jilbab', 145.000, NULL, NULL, 20,
   ARRAY['S','M','L','XL','XXL'], ARRAY['Noir','Beige','Gris','Marine'], ARRAY[]::text[], NULL,
   true, false, false),

  -- ═══ COLLECTION ACCESSOIRES ISLAMIQUES FEMME ═══
  ('epingles-hijab-premium',
   'دبابيس حجاب بريميوم', 'Épingles à Hijab Premium', 'Premium Hijab Pins',
   'دبابيس حجاب من معدن بريميوم. رأس مطلي بالذهب أو الفضة. طقم من 10 دبابيس متناسقة.',
   'Épingles à hijab en métal premium. Tête plaquée or ou argent. Set de 10 épingles assorties.',
   'accessoire', 25.000, NULL, NULL, 80,
   ARRAY['Pack 10'], ARRAY['Or','Argent','Champagne'], ARRAY[]::text[], NULL,
   true, false, false),

  ('bonnet-sous-hijab-bambou',
   'بونيه تحت الحجاب من الخيزران', 'Bonnet Sous-Hijab en Bambou', 'Bamboo Under-Scarf Bonnet',
   'بونيه تحت الحجاب من ألياف الخيزران، ناعم ومضاد للحساسية، يمتص العرق بشكل ممتاز.',
   'Bonnet sous-hijab en fibre de bambou, doux et anti-allergique, excellente absorption de la transpiration.',
   'accessoire', 18.000, NULL, NULL, 100,
   ARRAY['S','M'], ARRAY['Noir','Blanc','Beige','Taupe'], ARRAY['new'], 'new',
   true, false, false),

  ('set-ceinture-broche-abaya',
   'طقم حزام وبروش للعباية', 'Set Ceinture & Broche Abaya/Jilbab', 'Abaya Belt & Brooch Set',
   'طقم أنيق يتكون من حزام وبروش لتزيين العباية أو الجلباب وإبراز الخصر بذوق راقٍ.',
   'Set élégant composé d''une ceinture et d''une broche pour sublimer votre abaya ou jilbab avec raffinement.',
   'accessoire', 45.000, NULL, NULL, 35,
   ARRAY['Taille Unique'], ARRAY['Or','Argent','Noir'], ARRAY[]::text[], NULL,
   true, true, false),

  -- ═══ COLLECTION TAPIS DE PRIÈRE ═══
  ('tapis-priere-brode-luxe',
   'سجادة صلاة مطرزة فاخرة', 'Tapis de Prière Brodé Luxe', 'Luxury Embroidered Prayer Rug',
   'سجادة صلاة فاخرة بنسيج مخملي كثيف وتطريز أنيق. محراب مصمم بدقة ومريح للركبتين.',
   'Tapis de prière luxueux en velours dense avec broderies raffinées. Mihrab soigné, confortable pour les genoux.',
   'tapis', 65.000, NULL, NULL, 40,
   ARRAY['Taille Unique'], ARRAY['Bordeaux','Vert Émeraude','Bleu Nuit','Beige'], ARRAY['new'], 'new',
   true, true, false),

  ('tapis-priere-voyage-pliable',
   'سجادة صلاة سفر قابلة للطي', 'Tapis de Prière de Voyage Pliable', 'Foldable Travel Prayer Rug',
   'سجادة صلاة خفيفة وقابلة للطي مع حقيبة حمل، مثالية للسفر والعمل والاستخدام اليومي خارج المنزل.',
   'Tapis de prière léger et pliable avec pochette de transport, idéal pour le voyage, le travail et un usage nomade.',
   'tapis', 38.000, NULL, NULL, 55,
   ARRAY['Taille Unique'], ARRAY['Gris','Noir','Beige'], ARRAY[]::text[], NULL,
   true, false, false),

  ('set-tapis-sebha-housse',
   'طقم سجادة صلاة وسبحة وغلاف هدية', 'Set Tapis de Prière + Sebha + Housse Cadeau', 'Prayer Rug + Beads Gift Set',
   'طقم هدية راقٍ يضم سجادة صلاة، سبحة ذات جودة عالية وغلاف هدية أنيق. مثالي لرمضان والعيد.',
   'Coffret cadeau raffiné comprenant un tapis de prière, un sebha de qualité et un emballage cadeau élégant. Parfait pour le Ramadan et l''Aïd.',
   'tapis', 89.000, NULL, NULL, 25,
   ARRAY['Taille Unique'], ARRAY['Bordeaux','Vert','Bleu'], ARRAY['limited','gift'], 'limited',
   true, true, false)
ON CONFLICT (slug) DO NOTHING;

-- ── Médias produits (images Unsplash — libres de droits) ───────────────
INSERT INTO product_media (product_id, storage_path, alt_text, is_primary, sort_order)
SELECT p.id,
  CASE p.slug
    WHEN 'hijab-mousseline-premium-ivoire' THEN 'https://images.unsplash.com/photo-1585728748176-455ac5eed962?w=800&h=1067&fit=crop'
    WHEN 'hijab-soie-medine-luxe'          THEN 'https://images.unsplash.com/photo-1613611927458-3ddd4b0afdb9?w=800&h=1067&fit=crop'
    WHEN 'hijab-jersey-modal-doux'         THEN 'https://images.unsplash.com/photo-1613447895817-e617a4093f50?w=800&h=1067&fit=crop'
    WHEN 'hijab-crepe-signature'           THEN 'https://images.unsplash.com/photo-1552874869-5c39ec9288dc?w=800&h=1067&fit=crop'
    WHEN 'voile-chiffon-delicat'           THEN 'https://images.unsplash.com/photo-1640154853987-48e54d2ca0b8?w=800&h=1067&fit=crop'
    WHEN 'voile-nidha-prestige'            THEN 'https://images.unsplash.com/photo-1708151729245-fa18bd75727e?w=800&h=1067&fit=crop'
    WHEN 'khimar-long-premium'             THEN 'https://images.unsplash.com/photo-1640154852340-9de73a0643a8?w=800&h=1067&fit=crop'
    WHEN 'khimar-court-quotidien'          THEN 'https://images.unsplash.com/photo-1680125437968-80b0c794f0b1?w=800&h=1067&fit=crop'
    WHEN 'jilbab-classique-elegant'        THEN 'https://images.unsplash.com/photo-1662806407800-56793fa8e924?w=800&h=1067&fit=crop'
    WHEN 'jilbab-boutonne-moderne'         THEN 'https://images.unsplash.com/photo-1651828855150-ba40f6870a53?w=800&h=1067&fit=crop'
    WHEN 'jilbab-brode-ceremonie'          THEN 'https://images.unsplash.com/photo-1668028554854-245f8ccae15b?w=800&h=1067&fit=crop'
    WHEN 'jilbab-quotidien-confort'        THEN 'https://images.unsplash.com/photo-1613611927458-3ddd4b0afdb9?w=800&h=1067&fit=crop&sat=-20'
    WHEN 'epingles-hijab-premium'          THEN 'https://images.unsplash.com/photo-1552874869-5c39ec9288dc?w=800&h=1067&fit=crop&sat=-10'
    WHEN 'bonnet-sous-hijab-bambou'        THEN 'https://images.unsplash.com/photo-1613447895817-e617a4093f50?w=800&h=1067&fit=crop&sat=-10'
    WHEN 'set-ceinture-broche-abaya'       THEN 'https://images.unsplash.com/photo-1668028554854-245f8ccae15b?w=800&h=1067&fit=crop&sat=-10'
    WHEN 'tapis-priere-brode-luxe'         THEN 'https://images.unsplash.com/photo-1621700052663-f1170e9b26ec?w=800&h=1067&fit=crop'
    WHEN 'tapis-priere-voyage-pliable'     THEN 'https://images.unsplash.com/photo-1589725617374-6d1cd65c8014?w=800&h=1067&fit=crop'
    WHEN 'set-tapis-sebha-housse'          THEN 'https://images.unsplash.com/photo-1660338183700-12388dc9aa4f?w=800&h=1067&fit=crop'
    ELSE 'https://images.unsplash.com/photo-1585728748176-455ac5eed962?w=800&h=1067&fit=crop'
  END,
  p.name_ar || ' — استبرق',
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
   'تجربة رائعة! الحجاب أجمل بكثير من الصور. القماش فاخر جداً والخياطة محكمة. التوصيل كان سريعاً والدفع عند الاستلام مريح جداً.',
   'Expérience magnifique! Le hijab est bien plus beau qu''en photo. Tissu très haut de gamme, livraison rapide et paiement à la livraison très pratique.',
   true, true),

  ('منيرة العلوي',     '🇲🇦', 'الدار البيضاء، المغرب', 5,
   'أفضل بوتيك حشمة تعاملت معه. الجلباب المطرز تجاوز كل توقعاتي! الخدمة ممتازة والفريق محترف جداً.',
   'La meilleure boutique modest fashion avec laquelle j''ai traité. Le jilbab brodé a dépassé toutes mes attentes! Service excellent.',
   true, true),

  ('Amira Trabelsi',   '🇫🇷', 'Paris, France', 5,
   'حجاب استثنائي، خدمة ممتازة!',
   'Hijab en soie de Médine reçu à Paris sans problème! Service client impeccable et paiement sécurisé. Je recommande vivement Estabrak.',
   true, true),

  ('رانيا قاسم',        '🇹🇳', 'صفاقس', 5,
   'اشتريت طقم سجادة صلاة للعيد والجودة فاخرة جداً. التطريز رائع والألوان تماماً كما في الصور. شكراً لفريق استبرق!',
   'J''ai acheté un set tapis de prière pour l''Aïd et la qualité est vraiment luxueuse. La broderie est magnifique. Merci à l''équipe d''Estabrak!',
   true, false),

  ('Leila Ben Salah',  '🇹🇳', 'Sousse', 5,
   'زيارة رائعة لبوتيك استبرق في جربة',
   'Visitée lors d''un séjour à Djerba, la boutique Estabrak est une référence! Large gamme de hijabs et jilbabs, prix compétitifs et équipe accueillante.',
   true, false),

  ('خلود محمود',        '🇩🇿', 'الجزائر العاصمة', 4,
   'كجزائرية، سعيدة جداً بتجربة الشراء من استبرق. الجلابيب رائعة وأسعارها ممتازة. أنصح به بشدة!',
   'En tant qu''Algérienne, très satisfaite de mon achat chez Estabrak. Les jilbabs sont magnifiques et les prix excellents. Je recommande!',
   true, false),

  ('ياسمين الزهراني',  '🇸🇦', 'جدة، السعودية', 5,
   'طلبت خمار طويل وصلني في أحسن حال. الجودة تفوق ما توقعته. استبرق بوتيك راقٍ بحق.',
   'J''ai commandé un khimar long, reçu en parfait état. Qualité au-delà de mes attentes. Estabrak est vraiment une boutique de prestige.',
   true, true),

  ('Fatma Ayari',      '🇩🇪', 'Berlin, Allemagne', 5,
   'أهدت لي صديقة تونسية رابط استبرق',
   'Une amie tunisienne m''a recommandé Estabrak et je ne suis pas déçue! Le bonnet sous-hijab en bambou est incroyablement doux. Livraison internationale parfaite.',
   true, false)
ON CONFLICT DO NOTHING;

-- ── Coupons de bienvenue ──────────────────────────────────────────────
INSERT INTO coupons (code, description, discount_type, discount_value, min_purchase, max_uses, is_active)
VALUES
  ('ESTABRAK10',  'خصم 10% على أول طلب',           'percentage', 10,  50,  100, true),
  ('WELCOME20',   'خصم 20% للعملاء الجدد',          'percentage', 20,  150, 50,  true),
  ('DJERBA15',    'خصم 15 دينار على الطلبات الكبيرة','fixed',       15,  200, 200, true),
  ('EID2026',     'خصم العيد 15%',                  'percentage', 15,  100, 500, true),
  ('RAMADAN20',   'خصم رمضان على سجاد الصلاة',       'percentage', 20,  60,  300, true)
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
