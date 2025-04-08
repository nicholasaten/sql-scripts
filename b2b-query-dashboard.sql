-- Active User B2B Progress
SELECT
    u.id        AS user_id,
    -- CONCAT(SUBSTRING(u.email, 1, 3), '****@****') AS email,
    u.email     AS user_email,
    c2.name     AS company_name,
    cg.name     AS company_group_name,
    -- CONCAT(LEFT(c2.name, 3), '****') AS company_name,
    -- CONCAT(LEFT(cg.name, 3), '****') AS company_group_name,
    c.id        AS course_id,
    p.title     AS course_name,
    cp.complete AS progress,
    cp.created_at   AS first_accessed_at,
    cp.updated_at   AS last_accessed_at,
    cp.completed_at AS completed_at
FROM user_companies uc
JOIN users u ON u.id = uc.user_id
JOIN product_purchases pp ON pp.user_id = u.id
JOIN products p ON p.id = pp.product_id
JOIN product_courses pc ON pc.product_id = p.id
JOIN courses c ON c.id = pc.courses_id
JOIN company_groups cg ON cg.id = uc.company_group_id
JOIN companies c2 ON c2.id = uc.company_id
JOIN course_progress cp ON cp.user_id = u.id AND cp.course_id = c.id
WHERE uc.status = 'active'
    AND u.email NOT IN ('andrea@techconnect.co.id', 'hana.elizabeth@techconnect.co.id', 'maheswara.laksmono@techconnect.co.id', 'testing.greatnusa@gmail.com')
    [[AND cp.created_at BETWEEN {{start_date}} AND {{end_date}}]]
    [[AND uc.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
ORDER BY cp.created_at DESC;

-- Course Enrollment Growth
WITH first_access AS (
    SELECT
        u.id AS user_id,
        pc.product_id,
        MIN(cp.created_at) AS first_course_accessed_at
    FROM course_progress cp
    JOIN users u ON u.id = cp.user_id
    JOIN product_courses pc ON pc.courses_id = cp.course_id
    GROUP BY u.id, pc.product_id
)
SELECT
    EXTRACT(YEAR FROM fa.first_course_accessed_at) AS year,
    EXTRACT(MONTH FROM fa.first_course_accessed_at) AS month,
    COUNT(DISTINCT uc.user_id) AS total_enrolled
FROM first_access fa
JOIN users u ON u.id = fa.user_id
JOIN user_companies uc ON uc.user_id = u.id
JOIN companies c ON c.id = uc.company_id
JOIN products p ON p.id = fa.product_id
JOIN product_courses pc ON pc.product_id = p.id
JOIN courses c2 ON c2.id = pc.courses_id
LEFT JOIN course_progress cp ON cp.user_id = u.id AND cp.course_id = c2.id
WHERE
   uc.status = 'active'
    [[AND uc.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
    [[AND fa.first_course_accessed_at >= {{start_date}}]]
    [[AND fa.first_course_accessed_at <= {{end_date}}]]
GROUP BY
    year, month
ORDER BY
    year DESC, month DESC;

-- List of Course
SELECT distinct
    p.id AS course_id,
    p.type  AS course_type,
    p.title AS course_name,
    p.price AS course_price
FROM product_purchases pp
JOIN
    products p ON p.id = pp.product_id
JOIN
    user_companies uc ON uc.user_id = pp.user_id
JOIN
    users u ON u.id = uc.user_id
     LEFT JOIN discount_relations
                   ON discount_relations.model_id = uc.company_id
                       AND discount_relations.model_type = 'App\Models\Company'
         LEFT JOIN discounts
                   ON discounts.id = discount_relations.discount_id
WHERE
    uc.status = 'active'
    [[AND uc.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
    [[AND pp.created_at >= {{start_date}}]]
    [[AND pp.created_at <= {{end_date}}]];

-- List of Employees with Incomplete Modules
WITH first_access AS (
    SELECT
        u.id AS user_id,
        p.id AS product_id,
        MIN(cp.created_at) AS first_course_accessed_at
    FROM course_progress cp
    JOIN users u ON u.id = cp.user_id
    JOIN products p ON p.id = cp.course_id
    GROUP BY u.id, p.id
)
SELECT
   u.id AS user_id,
   u.name AS user_fullname,
--   CONCAT(SUBSTRING(u.email, 1, 3), '****@****') AS email,
  u.email AS user_email,
   p.title AS course_name,
   fa.first_course_accessed_at,
   CONCAT(COALESCE(cp.complete, 0), '%') AS course_progress,
   (CASE
       WHEN COALESCE(cp.complete, 0) = 100 THEN 'Completed'
       ELSE 'Not Completed'
   END) AS completion_status
FROM first_access fa
JOIN users u ON u.id = fa.user_id
JOIN user_companies uc ON uc.user_id = u.id
JOIN companies c ON c.id = uc.company_id
JOIN company_groups cg ON cg.id = uc.company_group_id
JOIN products p ON p.id = fa.product_id
JOIN product_courses pc ON pc.product_id = p.id
JOIN courses c2 ON c2.id = pc.courses_id
LEFT JOIN course_progress cp ON cp.user_id = u.id AND cp.course_id = c2.id
WHERE
   uc.status = 'active'
   AND COALESCE(cp.complete, 0) < 100
    [[AND uc.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
    [[AND fa.first_course_accessed_at >= {{start_date}}]]
    [[AND fa.first_course_accessed_at <= {{end_date}}]]
ORDER BY
   fa.first_course_accessed_at DESC;

-- Top 10 Course Category
SELECT
    COALESCE(c3.name, c2.name, c1.name, c.name) AS category_name,
    COUNT(cp.user_id) AS total_enroll
FROM
    product_purchases pp
JOIN
    users u ON u.id = pp.user_id
JOIN
    user_companies uc ON uc.user_id = u.id
JOIN
    companies co ON co.id = uc.company_id
JOIN
    products p ON p.id = pp.product_id
JOIN
    product_courses pc ON pc.product_id = p.id
JOIN
    courses c5 ON c5.id = pc.courses_id
JOIN
    course_progress cp ON cp.user_id = u.id AND cp.course_id = c5.id
LEFT JOIN
    category_relations cr ON cr.model_id = c5.id
LEFT JOIN
    categories c ON c.id = cr.category_id
LEFT JOIN
    categories c1 ON c1.id = c.parent_id
LEFT JOIN
    categories c2 ON c2.id = c1.parent_id
LEFT JOIN
    categories c3 ON c3.id = c2.parent_id
WHERE
    uc.status = 'active'
    AND cr.model_type LIKE '%Course'
    [[AND uc.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
    [[AND cp.created_at >= {{start_date}}]]
    [[AND cp.created_at <= {{end_date}}]]
GROUP BY
    category_name
ORDER BY
    total_enroll DESC
LIMIT 10;

-- Top 10 Courses
SELECT
    c2.id AS course_id,
    c2.title AS course_name,
    COUNT(cp.user_id) AS total_enroll
FROM
    product_purchases pp
JOIN
    users u ON u.id = pp.user_id
JOIN
    user_companies uc ON uc.user_id = u.id
JOIN
    companies c ON c.id = uc.company_id
JOIN
    products p ON p.id = pp.product_id
JOIN
    product_courses pc ON pc.product_id = p.id
JOIN
    courses c2 ON c2.id = pc.courses_id
LEFT JOIN
    course_progress cp ON cp.user_id = u.id AND cp.course_id = c2.id
WHERE
    uc.status = 'active'
    [[AND uc.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
    [[AND cp.created_at >= {{start_date}}]]
    [[AND cp.created_at <= {{end_date}}]]
GROUP BY
    c2.id, c2.title
ORDER BY
    total_enroll DESC
LIMIT 10;

-- Top 10 Users with Completed Courses
SELECT
    u.id AS user_id,
    u.name AS user_fullname,
    -- CONCAT(SUBSTRING(u.email, 1, 3), '****@****') AS user_email,
    u.email AS user_email,
    COUNT(c2.id) AS total_courses_completed
FROM
    product_purchases pp
JOIN
    users u ON u.id = pp.user_id
JOIN
    user_companies uc ON uc.user_id = u.id
JOIN
    companies c ON c.id = uc.company_id
JOIN
    products p ON p.id = pp.product_id
JOIN
    product_courses pc ON pc.product_id = p.id
JOIN
    courses c2 ON c2.id = pc.courses_id
LEFT JOIN
    course_progress cp ON cp.user_id = u.id AND cp.course_id = c2.id
WHERE
    uc.status = 'active'
    AND cp.complete = 100
    [[AND user_companies.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
    [[AND pp.created_at >= {{start_date}}]]
    [[AND pp.created_at <= {{end_date}}]]
GROUP BY
    u.id, u.name, u.username, u.email
ORDER BY
    total_courses_completed DESC
LIMIT 100;

-- Total Active Users
SELECT
    COUNT(DISTINCT uc.user_id) AS total_users_completed
FROM
    product_purchases pp
JOIN
    users u ON u.id = pp.user_id
JOIN
    user_companies uc ON uc.user_id = u.id
JOIN
    companies c ON c.id = uc.company_id
JOIN
    products p ON p.id = pp.product_id
JOIN
    product_courses pc ON pc.product_id = p.id
JOIN
    courses c2 ON c2.id = pc.courses_id
JOIN
    course_progress cp ON cp.user_id = u.id AND cp.course_id = c2.id
JOIN
    company_groups cg ON cg.id = uc.company_group_id
WHERE
    uc.status = 'active'
    [[AND uc.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
    [[AND pp.created_at >= {{start_date}}]]
    [[AND pp.created_at <= {{end_date}}]];

-- Total Amount Deposit
SELECT SUM(final_cost) AS wallet
FROM (

    SELECT '2024' AS year,
           '12' AS month,
           '2024-12' AS date,
           1 AS sort,
           NULL AS email,
           NULL AS name,
           NULL AS product_id,
           NULL AS product_title,
           NULL AS price,
           (SELECT SUM(wallets.amount) FROM wallets WHERE model_type = 'App\Models\Company' AND model_id = 34) AS final_cost,
           NULL AS enrolled_at,
           '2024-12-12 00:00:00' AS accessed_at,
           NULL AS completion
    UNION ALL

    SELECT '2024' AS year,
           '12' AS month,
           '2024-12' AS date,
           1 AS sort,
           NULL AS email,
           NULL AS name,
           NULL AS product_id,
           NULL AS product_title,
           NULL AS price,
           SUM(X.final_cost) AS final_cost,
           NULL AS enrolled_at,
           '2024-12-12 00:00:00' AS accessed_at,
           NULL AS completion
    FROM (
        SELECT EXTRACT(YEAR FROM course_progress.created_at) AS year,
               LPAD(EXTRACT(MONTH FROM course_progress.created_at)::TEXT, 2, '0') AS month,
               CONCAT(EXTRACT(YEAR FROM course_progress.created_at), '-', LPAD(EXTRACT(MONTH FROM course_progress.created_at)::TEXT, 2, '0')) AS date,
               2 AS sort,
               users.email,
               users.name,
               products.id AS product_id,
               products.title AS product_title,
               products.price,
               -products.price AS final_cost,
               product_purchases.created_at AS enrolled_at,
               course_progress.created_at AS accessed_at,
               course_progress.complete AS completion
        FROM user_companies
             JOIN users ON users.id = user_companies.user_id
             JOIN company_groups ON company_groups.id = user_companies.company_group_id
             JOIN product_purchases ON product_purchases.user_id = users.id
             JOIN products ON products.id = product_purchases.product_id
             JOIN course_progress ON course_progress.user_id = users.id
                 AND course_progress.course_id = products.id
             JOIN product_courses ON products.id = product_courses.product_id
        WHERE user_companies.status = 'active'
          [[AND user_companies.company_group_id = {{company_group_id}}]]
          [[AND user_companies.company_id = {{company_id}}]]
          [[AND course_progress.created_at BETWEEN {{start_date}} AND {{end_date}}]]
        ORDER BY date ASC, sort ASC, accessed_at DESC
    ) AS X
) AS Y;

-- Total Course Enrollments by User
WITH first_access AS (
    SELECT
        cp.user_id,
        cp.course_id,
        MIN(cp.created_at) AS first_accessed_at
    FROM course_progress cp
    GROUP BY cp.user_id, cp.course_id
)
SELECT
    COUNT(DISTINCT uc.user_id) AS user_count
FROM first_access fa
JOIN user_companies uc ON uc.user_id = fa.user_id
JOIN users u ON u.id = uc.user_id
JOIN company_groups cg ON cg.id = uc.company_group_id
JOIN product_purchases pp ON pp.user_id = fa.user_id
JOIN products p ON p.id = pp.product_id AND pp.product_id = p.id
JOIN course_progress cp ON cp.user_id = fa.user_id AND cp.course_id = p.id
WHERE
    uc.status = 'active'
    [[AND uc.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
    [[AND cp.created_at >= {{start_date}}]]
    [[AND cp.created_at <= {{end_date}}]];

-- Total Purchase Amount
SELECT SUM(final_cost) * -1 AS total_purchases
FROM (
    SELECT
        EXTRACT(YEAR FROM course_progress.created_at) AS year,
        EXTRACT(MONTH FROM course_progress.created_at) AS month,
        CONCAT(EXTRACT(YEAR FROM course_progress.created_at), '-', EXTRACT(MONTH FROM course_progress.created_at)) AS date,
        2 AS sort,
        users.email,
        users.name,
        products.id,
        products.title,
        products.price,
        -products.price AS final_cost,
        product_purchases.created_at AS enrolled_at,
        course_progress.created_at AS accessed_at,
        course_progress.complete AS completion
    FROM user_companies
    JOIN users ON users.id = user_companies.user_id
    JOIN company_groups ON company_groups.id = user_companies.company_group_id
    JOIN product_purchases ON product_purchases.user_id = users.id
    JOIN products ON products.id = product_purchases.product_id
    JOIN course_progress ON course_progress.user_id = users.id
        AND course_progress.course_id = products.id
    JOIN product_courses ON products.id = product_courses.product_id
    WHERE user_companies.status = 'active'
        [[AND user_companies.company_group_id = {{company_group_id}}]]
        [[AND user_companies.company_id = {{company_id}}]]
        [[AND course_progress.created_at >= {{start_date}}]]
        [[AND course_progress.created_at <= {{end_date}}]]
) AS X;

-- Total Purchase by Time
SELECT date, SUM(final_cost) * -1 AS total_purchases
FROM (
         SELECT EXTRACT(YEAR FROM cp.created_at)          AS year,
                EXTRACT(MONTH FROM cp.created_at)         AS month,
                CONCAT(EXTRACT(YEAR FROM cp.created_at), '-',
                       EXTRACT(MONTH FROM cp.created_at), '-', EXTRACT(DAY FROM cp.created_at)) AS date,
                2                                         AS sort,
                users.email,
                users.name,
                products.id,
                products.title,
                products.price,
                -(products.price)                        AS final_cost,
                product_purchases.created_at            AS enrolled_at,
                cp.created_at                            AS accessed_at,
                NULL                                     AS last_access,
                cp.complete                              AS completion
         FROM user_companies
                  JOIN users
                       ON users.id = user_companies.user_id
                  JOIN company_groups
                       ON company_groups.id = user_companies.company_group_id
                  JOIN product_purchases
                       ON product_purchases.user_id = users.id
                  JOIN products
                       ON products.id = product_purchases.product_id
                           AND product_purchases.product_id = products.id
                  INNER JOIN course_progress cp
                             ON cp.user_id = users.id
                                 AND cp.course_id = products.id
                                --  AND cp.created_at >= '2024-12-12'
                  JOIN product_courses
                       ON products.id = product_courses.product_id
                  LEFT JOIN course_progress cp2
                            ON cp2.user_id = users.id
                                AND cp2.course_id = product_courses.courses_id
         WHERE  user_companies.status = 'active'
           [[AND user_companies.company_group_id = {{company_group_id}}]]
           [[AND user_companies.company_id = {{company_id}}]]
           [[AND cp.created_at >= {{start_date}}]]
           [[AND cp.created_at <= {{end_date}}]]
         ORDER BY date ASC, sort ASC, accessed_at DESC
     ) AS X
GROUP BY date;

-- Total Registered Users
SELECT
    COUNT(uc.user_id) AS total_active_users
FROM
    user_companies uc
JOIN
    users u ON u.id = uc.user_id
JOIN
    companies c ON c.id = uc.company_id
JOIN
    company_groups cg ON cg.id = uc.company_group_id
WHERE
    uc.status = 'active'
    [[AND uc.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
    [[AND uc.created_at >= {{start_date}}]]
    [[AND uc.created_at <= {{end_date}}]];

-- Total User Over Group
SELECT
    EXTRACT(YEAR FROM uc.created_at) AS year,
    EXTRACT(MONTH FROM uc.created_at) AS month,
    EXTRACT(DAY FROM uc.created_at) AS day,
    cg.name AS group_name,
    -- CONCAT(LEFT(cg.name, 3), '****') AS group_name,
    COUNT(uc.user_id) AS new_users
FROM user_companies uc
JOIN users u ON u.id = uc.user_id
JOIN companies c ON c.id = uc.company_id
JOIN company_groups cg ON cg.id = uc.company_group_id
WHERE uc.created_at IS NOT NULL
[[AND uc.company_group_id = {{company_group_id}}]]
[[AND uc.company_id = {{company_id}}]]
[[AND uc.created_at >= {{start_date}}]]
[[AND uc.created_at <= {{end_date}}]]
GROUP BY year, month, day, cg.name
ORDER BY year, month, day;

-- Total Users Who Completed Courses
SELECT
    COUNT(distinct u.id) AS total_users_completed
FROM
    product_purchases pp
JOIN
    users u ON u.id = pp.user_id
JOIN
    user_companies uc ON uc.user_id = u.id
JOIN
    companies c ON c.id = uc.company_id
JOIN
    company_groups cg ON cg.id = uc.company_group_id
JOIN
    products p ON p.id = pp.product_id
JOIN
    product_courses pc ON pc.product_id = p.id
JOIN
    courses c2 ON c2.id = pc.courses_id
JOIN
    course_progress cp ON cp.user_id = u.id AND cp.course_id = c2.id
WHERE
    uc.status = 'active'
    AND cp.complete = 100
    [[AND uc.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
    [[AND pp.created_at >= {{start_date}}]]
    [[AND pp.created_at <= {{end_date}}]];

-- User Course Progress Overview
WITH first_access AS (
    SELECT
        u.id AS user_id,
        p.id AS product_id,
        MIN(cp.created_at) AS first_course_accessed_at
    FROM course_progress cp
    JOIN users u ON u.id = cp.user_id
    JOIN products p ON p.id = cp.course_id
    GROUP BY u.id, p.id
)
SELECT
   u.id AS user_id,
   u.name AS user_fullname,
--   CONCAT(SUBSTRING(u.email, 1, 3), '****@****') AS email,
    u.email AS email,
   p.title AS course_name,
   p.price AS final_cost,
   fa.first_course_accessed_at,
   CONCAT(COALESCE(cp.complete, 0), '%') AS course_progress
FROM first_access fa
JOIN users u ON u.id = fa.user_id
JOIN user_companies uc ON uc.user_id = u.id
JOIN companies c ON c.id = uc.company_id
JOIN company_groups cg ON cg.id = uc.company_group_id
JOIN products p ON p.id = fa.product_id
JOIN product_courses pc ON pc.product_id = p.id
JOIN courses c2 ON c2.id = pc.courses_id
LEFT JOIN course_progress cp ON cp.user_id = u.id AND cp.course_id = c2.id
WHERE
   uc.status = 'active'
    [[AND uc.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
    [[AND fa.first_course_accessed_at >= {{start_date}}]]
    [[AND fa.first_course_accessed_at <= {{end_date}}]]
ORDER BY
   fa.first_course_accessed_at DESC;

-- User Growth by Activity
WITH first_access AS (
    SELECT
        u.id AS user_id,
        MIN(cp.created_at) AS first_access_at
    FROM
        course_progress cp
    JOIN
        users u ON u.id = cp.user_id
    GROUP BY
        u.id
)
SELECT
    EXTRACT(YEAR FROM fa.first_access_at) AS year,
    EXTRACT(MONTH FROM fa.first_access_at) AS month,
    EXTRACT(DAY FROM fa.first_access_at) AS day,
    COUNT(DISTINCT uc.user_id) AS total_users
FROM
    user_companies uc
JOIN
    users u ON u.id = uc.user_id
JOIN
    companies c ON c.id = uc.company_id
JOIN
    company_groups cg ON cg.id = uc.company_group_id
JOIN
    first_access fa ON fa.user_id = uc.user_id
WHERE
    uc.status = 'active'
    [[AND uc.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
    [[AND fa.first_access_at >= {{start_date}}]]
    [[AND fa.first_access_at <= {{end_date}}]]
GROUP BY
    year, month, day
ORDER BY
    year, month, day;

-- User Growth by Registration
SELECT
    EXTRACT(YEAR FROM u.created_at) AS year,
    EXTRACT(MONTH FROM u.created_at) AS month,
    EXTRACT(DAY FROM u.created_at) AS day,
    COUNT(u.id) AS new_users
FROM user_companies uc
JOIN users u ON u.id = uc.user_id
JOIN companies c ON c.id = uc.company_id
JOIN company_groups cg ON cg.id = uc.company_group_id
WHERE u.created_at IS NOT NULL
AND uc.status = 'active'
[[AND uc.company_group_id = {{company_group_id}}]]
[[AND uc.company_id = {{company_id}}]]
[[AND u.created_at >= {{start_date}}]]
[[AND u.created_at <= {{end_date}}]]
GROUP BY year, month, day;

-- Users in Companies with Roles and Group Information
SELECT
    *
FROM user_companies uc
JOIN users u ON u.id = uc.user_id
JOIN companies c ON c.id = uc.company_id
JOIN company_groups cg ON cg.id = uc.company_group_id
JOIN roles r ON r.id = uc.role_id
WHERE
    uc.status = 'active'
    [[AND uc.company_group_id = {{company_group_id}}]]
    [[AND uc.company_id = {{company_id}}]]
    [[AND uc.created_at >= {{start_date}}]]
    [[AND uc.created_at <= {{end_date}}]];










