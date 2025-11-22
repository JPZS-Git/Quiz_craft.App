-- ============================================
-- RLS POLICIES FOR QUIZCRAFT
-- Apply these in Supabase SQL Editor
-- ============================================

-- Questions table policies
CREATE POLICY "Allow all operations for development" 
ON questions 
FOR ALL 
USING (true);

-- Answers table policies
CREATE POLICY "Allow all operations for development" 
ON answers 
FOR ALL 
USING (true);

-- Attempts table policies
CREATE POLICY "Allow all operations for development" 
ON attempts 
FOR ALL 
USING (true);

-- ============================================
-- NOTES:
-- These are permissive development policies
-- For production, replace with proper user-based policies:
-- USING (auth.uid() = user_id_column)
-- ============================================
