-- Distribusi Gender Peserta Event
SELECT
    gender,
    COUNT(email) AS total_users
FROM event_sis_berdaya_dana_2025
WHERE email IS NOT NULL
[[AND created_at BETWEEN {{start_date}} AND {{end_date}}]]
GROUP BY gender
ORDER BY total_users DESC;

-- Distribusi Peserta berdasarkan Provinsi
SELECT
    states.name AS state_name,
    COUNT(*) AS total_users
FROM event_sis_berdaya_dana_2025
JOIN states ON states.id = event_sis_berdaya_dana_2025.state_id
WHERE email IS NOT NULL
[[AND created_at BETWEEN {{start_date}} AND {{end_date}}]]
GROUP BY states.name
ORDER BY total_users DESC;

-- Enrollment Peserta Event
SELECT
    p.title AS course_name,
    COUNT(pp.user_id) AS total_users
FROM event_sis_berdaya_dana_2025 e
JOIN users u ON u.email = e.email
JOIN product_purchases pp ON pp.user_id = u.id AND pp.product_id IN (1208, 1200, 1117)
JOIN products p ON p.id = pp.product_id
WHERE e.email IS NOT NULL
[[AND e.created_at BETWEEN {{start_date}} AND {{end_date}}]]
GROUP BY p.title
ORDER BY total_users DESC;

-- Nilai Quiz Peserta dalam Course
SELECT DISTINCT ON (u.id, q.id)
    u.id AS user_id,
    CONCAT(SUBSTRING(u.email, 1, 3), '****@****') AS email,
    -- u.email,
    c.title AS course_name,
    q.name AS quiz_name,
    qs.score AS highest_score,
    qs.created_at AS completed_at
FROM event_sis_berdaya_dana_2025 e
JOIN users u ON u.email = e.email
JOIN product_purchases pp ON pp.user_id = u.id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
JOIN course_sections cs ON cs.course_id = c.id
JOIN course_materials cm ON cm.section_id = cs.id AND cm.type = 'quiz'
JOIN quizzes q ON q.id = cm.quiz_id
JOIN quiz_scores qs ON qs.user_id = u.id AND qs.quiz_id = q.id
WHERE e.email IS NOT NULL
    AND pp.product_id IN (1208, 1200, 1117)
    [[AND c.title = {{course_name}}]]
    [[AND qs.created_at BETWEEN {{start_date}} AND {{end_date}}]]
ORDER BY u.id, q.id, qs.score DESC;

-- Perkembangan Pendaftaran per Hari
SELECT
    DATE(created_at) AS registration_date,
    COUNT(*) AS total_users
FROM event_sis_berdaya_dana_2025
WHERE email IS NOT NULL
[[AND created_at BETWEEN {{start_date}} AND {{end_date}}]]
GROUP BY DATE(created_at)
ORDER BY registration_date;

-- Persebaran Penghasilan User
SELECT
    gross_income,
    COUNT(email) AS total_users
FROM event_sis_berdaya_dana_2025
WHERE email IS NOT NULL
[[AND created_at BETWEEN {{start_date}} AND {{end_date}}]]
GROUP BY gross_income
ORDER BY total_users DESC;


-- Progress Materi Pengguna dalam Kursus
SELECT DISTINCT
    u.id AS user_id,
    CONCAT(SUBSTRING(u.email, 1, 3), '****@****') AS email,
    -- u.email AS email,
    c.title AS course_name,
    COUNT(DISTINCT sp.material_id) AS materials_completed,
    (SELECT COUNT(*)
     FROM course_materials cm
     JOIN course_sections cs ON cs.id = cm.section_id
     WHERE cs.course_id = c.id) AS total_materials,
    (SELECT COUNT(*)
     FROM course_materials cm
     JOIN course_sections cs ON cs.id = cm.section_id
     WHERE cs.course_id = c.id) -
    COUNT(DISTINCT sp.material_id) AS materials_remaining
FROM event_sis_berdaya_dana_2025 e
JOIN users u ON u.email = e.email
JOIN product_purchases pp ON pp.user_id = u.id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
JOIN course_sections cs ON cs.course_id = c.id
JOIN course_materials cm ON cm.section_id = cs.id -- Hubungkan course_materials ke course lewat section
LEFT JOIN course_section_progress sp ON sp.user_id = u.id AND sp.material_id = cm.id -- Tracking progress
WHERE e.email IS NOT NULL
    AND pp.product_id IN (1208, 1200, 1117)
    [[AND c.title = {{course_name}}]]
    [[AND sp.create_at BETWEEN {{start_date}} AND {{end_date}}]]
GROUP BY u.id, u.email, c.title, c.id
ORDER BY email;

-- Rata-rata Usia Peserta
SELECT
    ROUND(AVG(EXTRACT(YEAR FROM NOW()) - CAST(year_of_birth AS INTEGER))) AS average_age
FROM event_sis_berdaya_dana_2025
WHERE email IS NOT NULL
[[AND created_at BETWEEN {{start_date}} AND {{end_date}}]];

-- Tingkat Penyelesaian Course oleh Peserta
SELECT
    c.title AS course_name,
    COUNT(CASE WHEN cp.complete = 100 THEN pp.user_id END) AS completed_users,
    COUNT(pp.user_id) AS total_users,
    ROUND(
        COUNT(CASE WHEN cp.complete = 100 THEN pp.user_id END) * 100.0 /
        NULLIF(COUNT(pp.user_id), 0), 2
    ) AS completion_rate
FROM event_sis_berdaya_dana_2025 e
JOIN users u ON u.email = e.email
JOIN product_purchases pp ON pp.user_id = u.id AND pp.product_id IN (1208, 1200, 1117)
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
LEFT JOIN course_progress cp ON cp.user_id = pp.user_id AND cp.course_id = c.id
WHERE e.email IS NOT NULL
[[AND cp.created_at BETWEEN {{start_date}} AND {{end_date}}]]
GROUP BY c.title
ORDER BY completion_rate DESC;


-- Total Registered Users
SELECT COUNT(*)
FROM event_sis_berdaya_dana_2025
WHERE email IS NOT NULL
    [[AND created_at = {{start_date}}]]
    [[AND created_at = {{end_date}}]]

--Tracking Course Completion Complete
SELECT DISTINCT
    u.id AS user_id,
    --CONCAT(SUBSTRING(u.email, 1, 3), '****@****') AS email,
    u.email AS email,
    c.title AS course_name,
    cp.complete,
    cp.created_at,
    cp.updated_at
FROM event_sis_berdaya_dana_2025 e
JOIN users u ON u.email = e.email
JOIN product_purchases pp ON pp.user_id = u.id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
LEFT JOIN course_progress cp ON cp.user_id = u.id AND cp.course_id = c.id
WHERE e.email IS NOT NULL
    AND pp.product_id IN (1208, 1200, 1117)
    AND cp.complete = 100
    [[AND c.title = {{course_name}}]]
    [[AND cp.created_at BETWEEN {{start_date}} AND {{end_date}}]]
ORDER BY email;

-- Tracking Course Completion Incomplete
SELECT DISTINCT
    u.id AS user_id,
    -- CONCAT(SUBSTRING(u.email, 1, 3), '****@****') AS email,
    u.email AS email,
    c.title AS course_name,
    cp.complete,
    cp.created_at,
    cp.updated_at
FROM event_sis_berdaya_dana_2025 e
JOIN users u ON u.email = e.email
JOIN product_purchases pp ON pp.user_id = u.id
JOIN product_courses pc ON pc.product_id = pp.product_id
JOIN courses c ON c.id = pc.courses_id
LEFT JOIN course_progress cp ON cp.user_id = u.id AND cp.course_id = c.id
WHERE e.email IS NOT NULL
    AND pp.product_id IN (1208, 1200, 1117)
    AND (cp.complete < 100 OR cp.complete IS NULL)
    [[AND c.title = {{course_name}}]]
    [[AND cp.created_at BETWEEN {{start_date}} AND {{end_date}}]]
ORDER BY email;

-- Tren Registrasi Harian/Mingguan
SELECT
    DATE(created_at) AS registration_date,
    COUNT(*) AS total_users
FROM event_sis_berdaya_dana_2025
WHERE email IS NOT NULL
[[AND created_at BETWEEN {{start_date}} AND {{end_date}}]]
GROUP BY DATE(created_at)
ORDER BY registration_date;



