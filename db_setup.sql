-- ============================================================
-- Student Portal Database Setup
-- Run these in your Supabase SQL Editor
-- ============================================================

-- 1. Add progress tracking to existing enrollments table
ALTER TABLE enrollments
ADD COLUMN IF NOT EXISTS progress INTEGER DEFAULT 0;

COMMENT ON COLUMN enrollments.progress IS 'Course completion percentage (0-100)';

-- 2. Certificates table (earned upon course completion)
CREATE TABLE IF NOT EXISTS certificates (
  certificate_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  student_id BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
  course_id INTEGER NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
  issue_date TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Student sticky notes (Profile > Notes tab)
CREATE TABLE IF NOT EXISTS student_notes (
  note_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  student_id BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  color TEXT DEFAULT '#FFFFF9C4',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Student activities / upcoming events (Profile page)
CREATE TABLE IF NOT EXISTS student_activities (
  activity_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  activity_date TIMESTAMPTZ NOT NULL,
  target_classes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Mock Data Insertion
-- Adjust student_id to match your logged-in student
-- ============================================================

-- Update enrollments with progress (student_id = 1 example)
UPDATE enrollments SET progress = 65 WHERE student_id = 1 AND course_id = 1;
UPDATE enrollments SET progress = 40 WHERE student_id = 1 AND course_id = 2;
UPDATE enrollments SET progress = 100 WHERE student_id = 1 AND course_id = 3;
UPDATE enrollments SET progress = 0  WHERE student_id = 1 AND course_id = 4;
UPDATE enrollments SET progress = 0  WHERE student_id = 1 AND course_id = 5;
UPDATE enrollments SET progress = 100 WHERE student_id = 1 AND course_id = 6;

-- Insert certificates for completed courses
INSERT INTO certificates (student_id, course_id, issue_date)
VALUES
  (1, 3, '2026-03-15'),
  (1, 6, '2026-04-10')
ON CONFLICT DO NOTHING;

-- Insert sticky notes
INSERT INTO student_notes (student_id, content, color)
VALUES
  (1, 'Review React hooks chapter before exam', '#FFFFF9C4'),
  (1, 'Submit Python assignment by Friday', '#FFFCE4EC')
ON CONFLICT DO NOTHING;

-- Insert upcoming activities
INSERT INTO student_activities (title, description, activity_date, target_classes)
VALUES
  ('Math Olympiad', 'Conducted for classes 8-9', '2025-05-30', 'classes 8-9'),
  ('Art Exhibition', 'Exhibition of new works', '2025-06-23', 'all students')
ON CONFLICT DO NOTHING;
