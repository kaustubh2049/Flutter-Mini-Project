-- Minimal patch for PropVista monetization + verification flow
-- Safe to run multiple times.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS plan_type TEXT DEFAULT 'free';

ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS is_boosted BOOLEAN DEFAULT FALSE;

ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS boost_expiry TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS public.verification_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  property_id UUID REFERENCES public.properties(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL,
  document_url TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'verification_requests'
      AND policyname = 'Users view own verification requests'
  ) THEN
    CREATE POLICY "Users view own verification requests"
      ON public.verification_requests
      FOR SELECT
      USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'verification_requests'
      AND policyname = 'Users insert own verification requests'
  ) THEN
    CREATE POLICY "Users insert own verification requests"
      ON public.verification_requests
      FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'verification_requests'
      AND policyname = 'Users update own pending verification requests'
  ) THEN
    CREATE POLICY "Users update own pending verification requests"
      ON public.verification_requests
      FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

INSERT INTO storage.buckets (id, name, public)
VALUES ('verification-docs', 'verification-docs', TRUE)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Users can upload verification docs'
  ) THEN
    CREATE POLICY "Users can upload verification docs"
      ON storage.objects
      FOR INSERT
      WITH CHECK (
        bucket_id = 'verification-docs'
        AND auth.role() = 'authenticated'
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Anyone can view verification docs'
  ) THEN
    CREATE POLICY "Anyone can view verification docs"
      ON storage.objects
      FOR SELECT
      USING (bucket_id = 'verification-docs');
  END IF;
END $$;
