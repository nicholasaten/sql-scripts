-- Highest Score User in Course
SELECT DISTINCT ON (u.id, q.id)
    u.id    AS user_id,
    -- CONCAT(SUBSTRING(u.email, 1, 3), '****@****') AS user_email,
    u.email AS user_email,
    c.id    AS course_id,
    c.title AS course_name,
    q.id    AS quiz_id,
    q.name  AS quiz_name,
    qs.total_attempts,
    qs.highest_score
FROM product_purchases pp
JOIN users u ON u.id = pp.user_id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
JOIN course_sections cs ON cs.course_id = c.id
JOIN course_materials cm ON cm.section_id = cs.id AND cm.type = 'quiz'
JOIN quizzes q ON q.id = cm.quiz_id
JOIN (
    SELECT qs.user_id, qs.quiz_id, COUNT(qs.id) AS total_attempts, MAX(qs.score) AS highest_score
    FROM quiz_scores qs
    GROUP BY qs.user_id, qs.quiz_id
) qs ON qs.quiz_id = q.id AND qs.user_id = u.id
WHERE c.id IN (85, 89)
    [[AND c.id = {{course_name}}]]
    [[AND qs.created_at BETWEEN {{start_date}} AND {{end_date}}]]
    [[AND u.email = {{user_email}}]]
ORDER BY u.id, q.id, qs.highest_score DESC;

-- Laporan Penyelesaian Materi User Berdasarkan Coure Section Progress
SELECT
    u.id    AS user_id,
    -- CONCAT(SUBSTRING(u.email, 1, 3), '****@****') AS user_email,
    u.email AS user_email,
    c.id    AS course_id,
    c.title AS course_name,
    COUNT(DISTINCT cm.id) AS total_material,
    COUNT(DISTINCT csp.section_id) AS completed_material,
    (COUNT(DISTINCT cm.id) - COUNT(DISTINCT csp.section_id)) AS remaining_material
FROM product_purchases pp
JOIN users u ON u.id = pp.user_id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
JOIN course_sections cs ON cs.course_id = c.id
JOIN course_materials cm ON cm.section_id = cs.id
LEFT JOIN course_section_progress csp ON csp.section_id = cs.id AND csp.user_id = u.id
WHERE c.id IN (85, 89)
    [[AND c.id = {{course_name}}]]
    [[AND csp.created_at BETWEEN {{start_date}} AND  {{end_date}}]]
    [[AND u.email = {{user_email}}]]
GROUP BY u.id, u.email, c.id, c.title
ORDER BY user_id, course_id;

-- List User Aktif Complete
SELECT
    u.id,
    u.name,
    -- CONCAT(SUBSTRING(u.email, 1, 3), '****@****') AS email,
    u.email,
    cp.complete,
    cp.created_at
FROM users u
JOIN product_purchases pp ON pp.user_id = u.id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
JOIN course_progress cp ON cp.course_id = c.id AND cp.user_id = u.id
WHERE c.id IN (85, 89)
    AND cp.complete = 100
    [[AND c.id = {{course_name}}]]
    [[AND cp.created_at BETWEEN {{start_date}} AND {{end_date}}]]
    [[AND u.email = {{user_email}}]]
ORDER BY cp.complete DESC

-- List User Aktif In Progress
SELECT
    u.id,
    u.name,
    -- CONCAT(SUBSTRING(u.email, 1, 3), '****@****') AS email,
    u.email,
    cp.complete AS progress_percentage,
    cp.created_at
FROM users u
JOIN product_purchases pp ON pp.user_id = u.id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
JOIN course_progress cp ON cp.course_id = c.id AND cp.user_id = u.id
WHERE c.id IN (85, 89)
    AND cp.complete > 0
    AND cp.complete <= 100
    [[AND c.id = {{course_name}}]]
    [[AND cp.created_at BETWEEN {{start_date}} AND {{end_date}}]]
    [[AND u.email = {{user_email}}]]
ORDER BY cp.complete DESC;

-- List User Inactive
SELECT
    u.id,
    u.name,
    -- CONCAT(SUBSTRING(u.email, 1, 3), '****@****') AS email,
    u.email,
    pp.created_at as enroll_created_at
FROM users u
JOIN product_purchases pp ON pp.user_id = u.id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
LEFT JOIN course_progress cp ON cp.course_id = c.id AND cp.user_id = u.id
WHERE c.id IN (85, 89)
    AND cp.user_id IS NULL
    [[AND c.id = {{course_name}}]]
    [[AND cp.created_at BETWEEN {{start_date}} AND {{end_date}}]]
    [[AND u.email = {{user_email}}]]
ORDER BY pp.created_at ASC;


-- Persentase User Aktif
SELECT
    'Active Users' AS category,
    (COUNT(DISTINCT cp.user_id) * 100.0 / COUNT(DISTINCT u.id)) AS percentage
FROM users u
JOIN product_purchases pp ON pp.user_id = u.id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
LEFT JOIN course_progress cp ON cp.course_id = c.id AND cp.user_id = u.id
WHERE c.id IN (85, 89)
    [[AND cp.created_at BETWEEN {{start_date}} AND {{end_date}}]]
    [[AND c.id = {{course_name}}]]

UNION ALL

SELECT
    'Inactive Users' AS category,
    (100 - (COUNT(DISTINCT cp.user_id) * 100.0 / COUNT(DISTINCT u.id))) AS percentage
FROM users u
JOIN product_purchases pp ON pp.user_id = u.id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
LEFT JOIN course_progress cp ON cp.course_id = c.id AND cp.user_id = u.id
WHERE c.id IN (85, 89)
    [[AND cp.created_at BETWEEN {{start_date}} AND {{end_date}}]]
    [[AND c.id = {{course_name}}]];

-- Progress All User dalam Kursus
SELECT 'Completed' AS status, COUNT(*) AS count
FROM users u
JOIN product_purchases pp ON pp.user_id = u.id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
LEFT JOIN course_progress cp ON cp.course_id = c.id AND cp.user_id = u.id
WHERE c.id IN (85, 89)
  [[AND c.id = {{course_name}}]]
  [[AND cp.created_at BETWEEN {{start_date}} AND {{end_date}}]]
  AND cp.complete = 100

UNION ALL

SELECT 'In Progress' AS status, COUNT(*) AS count
FROM users u
JOIN product_purchases pp ON pp.user_id = u.id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
LEFT JOIN course_progress cp ON cp.course_id = c.id AND cp.user_id = u.id
WHERE c.id IN (85, 89)
  [[AND c.id = {{course_name}}]]
  [[AND cp.created_at BETWEEN {{start_date}} AND {{end_date}}]]
  AND (cp.complete IS NOT NULL AND cp.complete < 100)

UNION ALL

SELECT 'Not Started' AS status, COUNT(*) AS count
FROM users u
JOIN product_purchases pp ON pp.user_id = u.id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
LEFT JOIN course_progress cp ON cp.course_id = c.id AND cp.user_id = u.id
WHERE c.id IN (85, 89)
  [[AND c.id = {{course_name}}]]
  [[AND cp.created_at BETWEEN {{start_date}} AND {{end_date}}]]
  AND cp.user_id IS NULL;

-- Total User Active
SELECT
    COUNT(cp.user_id)
FROM users u
JOIN product_purchases pp ON pp.user_id = u.id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
JOIN course_progress cp ON cp.course_id = c.id AND cp.user_id = u.id
WHERE c.id IN (85, 89)
    [[AND c.id = {{course_name}}]]
    [[AND pp.created_at BETWEEN {{start_date}} AND  {{end_date}}]];

-- Total User Enroll
select
    COUNT(*)
FROM product_purchases pp
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
WHERE c.id IN (85, 89)
    [[AND c.id = {{course_name}}]]
    [[AND pp.created_at BETWEEN {{start_date}} AND {{end_date}}]];

-- Total User Inactive
SELECT
    COUNT(DISTINCT pp.user_id) AS total_enrolled_users,
    COUNT(DISTINCT cp.user_id) AS total_active_users,
    COUNT(DISTINCT pp.user_id) - COUNT(DISTINCT cp.user_id) AS total_inactive_users
FROM product_purchases pp
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
LEFT JOIN course_progress cp ON cp.course_id = c.id AND cp.user_id = pp.user_id
WHERE c.id IN (85, 89)
    [[AND c.id = {{course_name}}]]
    [[AND pp.created_at BETWEEN {{start_date}} AND {{end_date}}]];

-- User Detail Progress
SELECT
    u.id AS user_id,
    u.name AS user_name,
    u.email AS user_email,
    c.id    AS course_id,
    c.title AS course_name,
    cs.id AS section_id,
    cs.title AS section_name,
    cm.id AS material_id,
    cm.title AS material_name,
    csp.created_at AS first_accessed_at,
    csp.updated_at AS last_accessed_at,
    CASE
        WHEN csp.updated_at IS NOT NULL THEN 'Complete'
        ELSE 'Incomplete'
    END AS material_status
FROM product_purchases pp
JOIN users u ON u.id = pp.user_id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
JOIN course_sections cs ON cs.course_id = c.id
JOIN course_materials cm ON cm.section_id = cs.id
LEFT JOIN course_section_progress csp
    ON csp.section_id = cs.id
   AND csp.material_id = cm.id
   AND csp.user_id = u.id
WHERE c.id IN (85, 89)
    [[AND u.email = {{user_email}}]]
    [[AND c.id = {{course_id}}]]
    [[AND csp.created_at BETWEEN {{start_date}} AND {{end_date}}]]
ORDER BY u.id DESC, cs.id ASC, cm.id ASC;
