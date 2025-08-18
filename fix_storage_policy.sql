-- Storage 정책 수정 (RLS 오류 해결)
-- Supabase 대시보드의 SQL Editor에서 실행하세요

-- 1. 기존 정책들 삭제
DROP POLICY IF EXISTS "Public read access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated delete access" ON storage.objects;

-- 2. 더 간단한 정책으로 다시 생성
-- 모든 사용자가 book-covers 버킷에 접근 가능하도록 설정

-- 읽기 정책 (누구나 볼 수 있음)
CREATE POLICY "Allow public read access" ON storage.objects
FOR SELECT USING (bucket_id = 'book-covers');

-- 업로드 정책 (누구나 업로드 가능)
CREATE POLICY "Allow public upload access" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'book-covers');

-- 업데이트 정책 (누구나 업데이트 가능)
CREATE POLICY "Allow public update access" ON storage.objects
FOR UPDATE USING (bucket_id = 'book-covers');

-- 삭제 정책 (누구나 삭제 가능)
CREATE POLICY "Allow public delete access" ON storage.objects
FOR DELETE USING (bucket_id = 'book-covers');

-- 3. 버킷이 public인지 확인
UPDATE storage.buckets 
SET public = true 
WHERE id = 'book-covers';

