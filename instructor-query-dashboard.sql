-- Daftar Produk dan Instruktur
SELECT * FROM (
SELECT
    p.id    AS product_id,
    p.type  AS product_type,
    p.title AS product_name,
    u.name  AS instructor_name,
    CONCAT('https://greatnusa.com/product/', p.slug) AS link_product
FROM products p
JOIN product_courses pc ON pc.product_id = p.id
JOIN courses c ON c.id = pc.courses_id
JOIN course_instructors ci ON ci.course_id = c.id
JOIN instructors i ON i.id = ci.instructor_id
JOIN users u ON u.id = i.user_id
WHERE p.type = 'course'

UNION ALL

SELECT
    p.id    AS product_id,
    p.type  AS product_type,
    p.title AS product_name,
    u.name  AS instructor_name,
    CONCAT('https://greatnusa.com/product/', p.slug) AS link_product
FROM products p
JOIN product_webinars pc ON pc.product_id = p.id
JOIN webinars c ON c.id = pc.webinar_id
JOIN webinar_instructors ci ON ci.webinar_id = c.id
JOIN instructors i ON i.id = ci.instructor_id
JOIN users u ON u.id = i.user_id
WHERE p.type = 'event'

UNION ALL

SELECT
    p.id    AS product_id,
    p.type  AS product_type,
    p.title AS product_name,
    u.name  AS instructor_name,
    CONCAT('https://greatnusa.com/product/', p.slug) AS link_product
FROM products p
JOIN product_bootcamps pc ON pc.product_id = p.id
JOIN bootcamps c ON c.id = pc.bootcamp_id
JOIN bootcamp_instructors ci ON ci.bootcamp_id = c.id
JOIN instructors i ON i.id = ci.instructor_id
JOIN users u ON u.id = i.user_id
WHERE p.type = 'bootcamp') AS all_products
WHERE 1=1
    [[AND product_type = {{course_type}}]]
    [[AND instructor_id = {{instructor_id}}]]
    [[AND product_id = {{product_id}}]]

-- Total Jumlah Peserta
SELECT
    instructor_id,
    instructor_name,
    SUM(total_students) AS total_students
FROM (
    SELECT
        i.id AS instructor_id,
        u.name AS instructor_name,
        COUNT(DISTINCT pe.user_id) AS total_students
    FROM instructors i
    JOIN users u ON u.id = i.user_id
    JOIN course_instructors ci ON ci.instructor_id = i.id
    JOIN courses c ON c.id = ci.course_id
    JOIN product_courses pc ON pc.courses_id = c.id
    JOIN products p ON p.id = pc.product_id
    JOIN product_purchases pe ON pe.product_id = p.id
    WHERE p.type = 'course'
    GROUP BY i.id, u.name

    UNION ALL

    SELECT
        i.id AS instructor_id,
        u.name AS instructor_name,
        COUNT(DISTINCT pe.user_id) AS total_students
    FROM instructors i
    JOIN users u ON u.id = i.user_id
    JOIN webinar_instructors wi ON wi.instructor_id = i.id
    JOIN webinars w ON w.id = wi.webinar_id
    JOIN product_webinars pw ON pw.webinar_id = w.id
    JOIN products p ON p.id = pw.product_id
    JOIN product_purchases pe ON pe.product_id = p.id
    WHERE p.type = 'event'
    GROUP BY i.id, u.name

    UNION ALL

    SELECT
        i.id AS instructor_id,
        u.name AS instructor_name,
        COUNT(DISTINCT pe.user_id) AS total_students
    FROM instructors i
    JOIN users u ON u.id = i.user_id
    JOIN bootcamp_instructors bi ON bi.instructor_id = i.id
    JOIN bootcamps b ON b.id = bi.bootcamp_id
    JOIN product_bootcamps pb ON pb.bootcamp_id = b.id
    JOIN products p ON p.id = pb.product_id
    JOIN product_purchases pe ON pe.product_id = p.id
    WHERE p.type = 'bootcamp'
    GROUP BY i.id, u.name
) AS total_students_per_instructor
WHERE 1=1
[[AND instructor_id = {{instructor_id}}]]
[[AND product_id = {{product_id}}]]
GROUP BY instructor_id, instructor_name
ORDER BY total_students DESC;

-- Total Product by Instructor
-- Total Product by Instructor (with filter in Metabase)
SELECT
    instructor_id,
    instructor_name,
    SUM(total_products) AS total_products
FROM (
    SELECT
        i.id AS instructor_id,
        u.name AS instructor_name,
        COUNT(DISTINCT p.id) AS total_products
    FROM instructors i
    JOIN users u ON u.id = i.user_id
    JOIN course_instructors ci ON ci.instructor_id = i.id
    JOIN courses c ON c.id = ci.course_id
    JOIN product_courses pc ON pc.courses_id = c.id
    JOIN products p ON p.id = pc.product_id
    WHERE p.type = 'course'
    GROUP BY i.id, u.name

    UNION ALL

    SELECT
        i.id AS instructor_id,
        u.name AS instructor_name,
        COUNT(DISTINCT p.id) AS total_products
    FROM instructors i
    JOIN users u ON u.id = i.user_id
    JOIN webinar_instructors wi ON wi.instructor_id = i.id
    JOIN webinars w ON w.id = wi.webinar_id
    JOIN product_webinars pw ON pw.webinar_id = w.id
    JOIN products p ON p.id = pw.product_id
    WHERE p.type = 'event'
    GROUP BY i.id, u.name

    UNION ALL

    SELECT
        i.id AS instructor_id,
        u.name AS instructor_name,
        COUNT(DISTINCT p.id) AS total_products
    FROM instructors i
    JOIN users u ON u.id = i.user_id
    JOIN bootcamp_instructors bi ON bi.instructor_id = i.id
    JOIN bootcamps b ON b.id = bi.bootcamp_id
    JOIN product_bootcamps pb ON pb.bootcamp_id = b.id
    JOIN products p ON p.id = pb.product_id
    WHERE p.type = 'bootcamp'
    GROUP BY i.id, u.name
) AS total_products_per_instructor
WHERE 1=1
[[AND instructor_id = {{instructor_id}}]]
GROUP BY instructor_id, instructor_name
ORDER BY total_products DESC;

-- User Progress by Instructor
SELECT *
FROM (
    SELECT
        u.id           AS user_id,
        u.email        AS user_email,
        c.id           AS content_id,
        c.title        AS content_name,
        'Course'       AS content_type,
        i.user_id      AS instructor_id,
        u2.name        AS instructor_name,
        COALESCE(MAX(cp.complete), 0) AS percentage,
        MIN(cp.created_at) AS first_accessed_at,
        MAX(cp.updated_at) AS last_accessed_at,
        MAX(cp.completed_at) AS completed_at
    FROM product_purchases pp
    JOIN products p ON p.id = pp.product_id
    JOIN users u ON u.id = pp.user_id
    JOIN product_courses pc ON pc.product_id = pp.product_id
    JOIN courses c ON c.id = pc.courses_id
    LEFT JOIN course_progress cp ON cp.course_id = c.id AND cp.user_id = u.id
    JOIN course_instructors ci ON ci.course_id = c.id
    JOIN instructors i ON i.id = ci.instructor_id
    JOIN users u2 ON u2.id = i.user_id
    WHERE 1=1
    [[AND i.id = {{instructor_id}}]]
    [[AND p.id = {{product_id}}]]
    GROUP BY u.id, u.email, c.id, c.title, i.user_id, u2.name

    UNION ALL

    SELECT
        u.id           AS user_id,
        u.email        AS user_email,
        c.id           AS content_id,
        c.title        AS content_name,
        'Webinar'      AS content_type,
        i.user_id      AS instructor_id,
        u2.name        AS instructor_name,
        COALESCE(MAX(cp.complete), 0) AS percentage,
        MIN(cp.created_at) AS first_accessed_at,
        MAX(cp.updated_at) AS last_accessed_at,
        MAX(cp.completed_at) AS completed_at
    FROM product_purchases pp
    JOIN products p ON p.id = pp.product_id
    JOIN users u ON u.id = pp.user_id
    JOIN product_webinars pc ON pc.product_id = pp.product_id
    JOIN webinars c ON c.id = pc.webinar_id
    LEFT JOIN webinar_progress cp ON cp.webinar_id = c.id AND cp.user_id = u.id
    JOIN webinar_instructors ci ON ci.webinar_id = c.id
    JOIN instructors i ON i.id = ci.instructor_id
    JOIN users u2 ON u2.id = i.user_id
    WHERE 1=1
    [[AND i.id = {{instructor_id}}]]
    [[AND p.id = {{product_id}}]]
    GROUP BY u.id, u.email, c.id, c.title, i.user_id, u2.name

    UNION ALL

    SELECT
        u.id           AS user_id,
        u.email        AS user_email,
        c.id           AS content_id,
        c.title        AS content_name,
        'Bootcamp'     AS content_type,
        i.user_id      AS instructor_id,
        u2.name        AS instructor_name,
        COALESCE(MAX(cp.complete), 0) AS percentage,
        MIN(cp.created_at) AS first_accessed_at,
        MAX(cp.updated_at) AS last_accessed_at,
        MAX(cp.completed_at) AS completed_at
    FROM product_purchases pp
    JOIN users u ON u.id = pp.user_id
    JOIN products p ON p.id = pp.product_id
    JOIN product_bootcamps pc ON pc.product_id = pp.product_id
    JOIN bootcamps c ON c.id = pc.bootcamp_id
    LEFT JOIN bootcamp_progress cp ON cp.bootcamp_id = c.id AND cp.user_id = u.id
    JOIN bootcamp_instructors ci ON ci.bootcamp_id = c.id
    JOIN instructors i ON i.id = ci.instructor_id
    JOIN users u2 ON u2.id = i.user_id
    WHERE 1=1
    [[AND i.id = {{instructor_id}}]]
    [[AND p.id = {{product_id}}]]
    GROUP BY u.id, u.email, c.id, c.title, i.user_id, u2.name
) AS combined_results
ORDER BY percentage DESC;
