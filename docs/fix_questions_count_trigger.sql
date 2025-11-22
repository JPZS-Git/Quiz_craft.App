-- ============================================
-- FIX QUESTIONS_COUNT TRIGGER
-- Execute este SQL no Supabase SQL Editor
-- ============================================

-- 1. Remover trigger e função existentes (se houver)
DROP TRIGGER IF EXISTS trigger_update_quizzes_questions_count ON questions;
DROP FUNCTION IF EXISTS update_quizzes_questions_count();

-- 2. Criar a função que atualiza questions_count
CREATE OR REPLACE FUNCTION update_quizzes_questions_count()
RETURNS TRIGGER AS $$
DECLARE
  quiz_id_to_update UUID;
BEGIN
  -- Determinar qual quiz_id atualizar
  IF TG_OP = 'INSERT' THEN
    quiz_id_to_update := NEW.quiz_id;
  ELSIF TG_OP = 'DELETE' THEN
    quiz_id_to_update := OLD.quiz_id;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Se o quiz_id mudou, atualizar ambos
    IF NEW.quiz_id != OLD.quiz_id THEN
      -- Recalcular para o quiz antigo
      UPDATE quizzes 
      SET questions_count = (
        SELECT COUNT(*) 
        FROM questions 
        WHERE quiz_id = OLD.quiz_id
      ),
      updated_at = now()
      WHERE id = OLD.quiz_id;
    END IF;
    quiz_id_to_update := NEW.quiz_id;
  END IF;
  
  -- Recalcular o contador para o quiz afetado
  UPDATE quizzes 
  SET questions_count = (
    SELECT COUNT(*) 
    FROM questions 
    WHERE quiz_id = quiz_id_to_update
  ),
  updated_at = now()
  WHERE id = quiz_id_to_update;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. Criar o trigger para INSERT, UPDATE e DELETE
CREATE TRIGGER trigger_update_quizzes_questions_count
AFTER INSERT OR UPDATE OR DELETE ON questions
FOR EACH ROW
EXECUTE FUNCTION update_quizzes_questions_count();

-- 4. Recalcular questions_count para todos os quizzes existentes
UPDATE quizzes
SET questions_count = (
  SELECT COUNT(*)
  FROM questions
  WHERE questions.quiz_id = quizzes.id
);

-- 5. Verificar se o trigger foi criado
SELECT 
  trigger_name, 
  event_object_table, 
  action_timing,
  event_manipulation
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_update_quizzes_questions_count';

-- 6. Mostrar contagem atual de perguntas por quiz
SELECT 
  q.id,
  q.title,
  q.questions_count as "count_na_tabela",
  (SELECT COUNT(*) FROM questions WHERE quiz_id = q.id) as "count_real"
FROM quizzes q
ORDER BY q.created_at DESC;
