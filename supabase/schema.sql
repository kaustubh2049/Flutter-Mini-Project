-- ============================================================
--  PropVista – Supabase Database Schema
--  Run this entire file in: Supabase Dashboard → SQL Editor
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────────────────────
--  PROFILES (extends auth.users – auto-created via trigger)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.profiles (
    id          UUID        REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name        TEXT,
    email       TEXT,
    phone       TEXT,
    avatar_url  TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Trigger: auto-create profile when a user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, name, email, phone)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data ->> 'name',
        NEW.email,
        NEW.raw_user_meta_data ->> 'phone'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─────────────────────────────────────────────────────────────
--  PROPERTIES
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.properties (
    id            UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    owner_id      UUID        REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

    -- Core details
    title         TEXT        NOT NULL,
    type          TEXT        NOT NULL CHECK (type IN ('Apartment','Villa','PG','Plot','House','Office','Commercial')),
    listing_type  TEXT        NOT NULL CHECK (listing_type IN ('Rent','Buy')),
    bhk           INT         CHECK (bhk BETWEEN 1 AND 10),
    price         NUMERIC     NOT NULL,            -- rent/month or sale price in ₹
    area          NUMERIC,                          -- sq. ft.
    floor         TEXT,

    -- Location (locality-first, Indian convention)
    locality      TEXT        NOT NULL,
    city          TEXT        NOT NULL,
    state         TEXT,

    -- Content
    description   TEXT,
    amenities     TEXT[]      DEFAULT '{}',
    image_urls    TEXT[]      DEFAULT '{}',        -- Firebase / Supabase Storage URLs

    -- Owner contact (denormalised for speed)
    owner_name    TEXT,
    owner_phone   TEXT,                            -- used for WhatsApp deep link

    -- Flags
    is_verified   BOOLEAN     DEFAULT FALSE,
    is_featured   BOOLEAN     DEFAULT FALSE,
    is_active     BOOLEAN     DEFAULT TRUE,

    posted_at     TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at    TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ─────────────────────────────────────────────────────────────
--  SAVED / BOOKMARKED PROPERTIES
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.saved_properties (
    id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id     UUID        REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    property_id UUID        REFERENCES public.properties(id) ON DELETE CASCADE NOT NULL,
    saved_at    TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE (user_id, property_id)
);

-- ─────────────────────────────────────────────────────────────
--  PROPERTY INTERESTS
--  Buyer taps "I'm Interested" → record inserted here
--  Seller can count how many buyers expressed interest
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.property_interests (
    id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    property_id UUID        REFERENCES public.properties(id) ON DELETE CASCADE NOT NULL,
    user_id     UUID        REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE (property_id, user_id)
);

ALTER TABLE public.property_interests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Buyers view own interests"
    ON public.property_interests FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Sellers see interests on their properties"
    ON public.property_interests FOR SELECT
    USING (
        property_id IN (SELECT id FROM public.properties WHERE owner_id = auth.uid())
    );

CREATE POLICY "Buyers express interest"
    ON public.property_interests FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Buyers withdraw interest"
    ON public.property_interests FOR DELETE USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────
--  ROW LEVEL SECURITY
-- ─────────────────────────────────────────────────────────────

-- Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Properties
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can browse active listings"
    ON public.properties FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Authenticated users can post listings"
    ON public.properties FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Owners can edit their listings"
    ON public.properties FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Owners can delete their listings"
    ON public.properties FOR DELETE USING (auth.uid() = owner_id);

-- Saved Properties
ALTER TABLE public.saved_properties ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own saved"
    ON public.saved_properties FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can save a property"
    ON public.saved_properties FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unsave a property"
    ON public.saved_properties FOR DELETE USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────
--  STORAGE BUCKET  (property images – public)
-- ─────────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('property-images', 'property-images', TRUE)
ON CONFLICT DO NOTHING;

CREATE POLICY "Anyone can view property images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'property-images');

CREATE POLICY "Authenticated users can upload"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'property-images' AND auth.role() = 'authenticated');

CREATE POLICY "Owners can delete their images"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'property-images'
           AND auth.uid()::text = (storage.foldername(name))[1]);

-- ─────────────────────────────────────────────────────────────
--  PERFORMANCE INDEXES
-- ─────────────────────────────────────────────────────────────
CREATE INDEX idx_properties_listing_type ON public.properties(listing_type);
CREATE INDEX idx_properties_city         ON public.properties(city);
CREATE INDEX idx_properties_locality     ON public.properties(locality);
CREATE INDEX idx_properties_owner_id     ON public.properties(owner_id);
CREATE INDEX idx_properties_posted_at    ON public.properties(posted_at DESC);
CREATE INDEX idx_properties_is_featured  ON public.properties(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_saved_user_id           ON public.saved_properties(user_id);

-- ─────────────────────────────────────────────────────────────
--  VISIT REQUESTS
--  Buyer taps "Schedule Visit" → record inserted here
--  Seller can see all visit requests on their properties
--  User info is denormalised so sellers can see details without
--  needing cross-profile SELECT (which RLS would block).
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.visit_requests (
    id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    property_id UUID        REFERENCES public.properties(id) ON DELETE CASCADE NOT NULL,
    user_id     UUID        REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    user_name   TEXT,
    user_phone  TEXT,
    user_email  TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE (property_id, user_id)
);

ALTER TABLE public.visit_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Buyers can request visits"
    ON public.visit_requests FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Buyers view own requests"
    ON public.visit_requests FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Sellers see visit requests on their properties"
    ON public.visit_requests FOR SELECT
    USING (
        property_id IN (SELECT id FROM public.properties WHERE owner_id = auth.uid())
    );

CREATE POLICY "Buyers withdraw visit requests"
    ON public.visit_requests FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_visit_requests_property_id ON public.visit_requests(property_id);
CREATE INDEX idx_visit_requests_user_id     ON public.visit_requests(user_id);

-- ─────────────────────────────────────────────────────────────
--  SEED DATA (optional demo listings – remove before production)
-- ─────────────────────────────────────────────────────────────
-- INSERT INTO public.properties (owner_id, title, type, listing_type, bhk, price,
--   area, locality, city, state, description, owner_name, owner_phone,
--   is_verified, is_featured, image_urls)
-- VALUES (
--   '<your-auth-user-id>',
--   '3 BHK Apartment in Koramangala',
--   'Apartment', 'Rent', 3, 35000,
--   1450, 'Koramangala', 'Bangalore', 'Karnataka',
--   'Spacious 3BHK with modular kitchen, gym, and 24x7 security.',
--   'Rahul Sharma', '9876543210',
--   TRUE, TRUE,
--   ARRAY['https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800']
-- );
