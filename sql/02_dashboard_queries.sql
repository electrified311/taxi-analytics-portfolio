-- ==============================================
-- ОПЕРАТИВНЫЕ МЕТРИКИ (LIVE)
-- ==============================================

-- 1. Конверсия заказов в поездки (сегодня / вчера)
WITH today AS (
    SELECT 
        COUNT(DISTINCT o.order_id) as orders,
        COUNT(DISTINCT r.order_id) as rides
    FROM orders o
    LEFT JOIN rides r ON o.order_id = r.order_id
    WHERE DATE(o.created_at) = CURRENT_DATE
),
yesterday AS (
    SELECT 
        COUNT(DISTINCT o.order_id) as orders,
        COUNT(DISTINCT r.order_id) as rides
    FROM orders o
    LEFT JOIN rides r ON o.order_id = r.order_id
    WHERE DATE(o.created_at) = CURRENT_DATE - 1
),
stats AS (
    SELECT 
        ROUND(100.0 * t.rides / NULLIF(t.orders, 0), 1) as today_conv,
        ROUND(100.0 * y.rides / NULLIF(y.orders, 0), 1) as yesterday_conv,
        TO_CHAR(CURRENT_DATE, 'DD.MM.YY') as d_today,
        TO_CHAR(CURRENT_DATE - 1, 'DD.MM.YY') as d_yesterday
    FROM today t, yesterday y
),
final_calc AS (
    SELECT *,
        CASE 
            WHEN yesterday_conv = 0 THEN 0 
            ELSE ROUND(100.0 * (today_conv - yesterday_conv) / yesterday_conv, 1) 
        END as change_pct
    FROM stats
)
SELECT 
    '<div style="text-align:center;">
        <small style="color:gray;">Сегодня (' || d_today || ')</small><br>
        <b style="font-size:24px;">' || today_conv || '%</b>
    </div>' as "Сегодня",
    '<div style="text-align:center;">
        <small style="color:gray;">Вчера (' || d_yesterday || ')</small><br>
        <b style="font-size:20px; color:#666;">' || yesterday_conv || '%</b>
    </div>' as "Вчера",
    '<div style="text-align:center;">
        <small style="color:gray;">Изменение</small><br>
        <b style="font-size:20px; color:' || CASE WHEN change_pct >= 0 THEN '#27ae60' ELSE '#e74c3c' END || ';">' 
        || CASE WHEN change_pct >= 0 THEN '▲ ' ELSE '▼ ' END
        || ABS(change_pct) || '%</b>
    </div>' as "Динамика"
FROM final_calc;

-- 2. Средний чек (сегодня / вчера)
WITH today AS (
    SELECT COALESCE(AVG(ride_price), 0) as avg_check
    FROM rides
    WHERE DATE(ride_started_at) = CURRENT_DATE
),
yesterday AS (
    SELECT COALESCE(AVG(ride_price), 0) as avg_check
    FROM rides
    WHERE DATE(ride_started_at) = CURRENT_DATE - 1
),
stats AS (
    SELECT 
        TO_CHAR(ROUND(t.avg_check, 0), 'FM999G999G999') as today_avg_str,
        TO_CHAR(ROUND(y.avg_check, 0), 'FM999G999G999') as yesterday_avg_str,
        t.avg_check as t_raw,
        y.avg_check as y_raw,
        TO_CHAR(CURRENT_DATE, 'DD.MM.YY') as d_today,
        TO_CHAR(CURRENT_DATE - 1, 'DD.MM.YY') as d_yesterday
    FROM today t, yesterday y
),
final_calc AS (
    SELECT *,
        CASE 
            WHEN y_raw = 0 THEN 0 
            ELSE ROUND(100.0 * (t_raw - y_raw) / y_raw, 1) 
        END as change_pct
    FROM stats
)
SELECT 
    '<div style="text-align:center;">
        <small style="color:gray;">Сегодня (' || d_today || ')</small><br>
        <b style="font-size:24px;">' || today_avg_str || ' ₽</b>
    </div>' as "Сегодня",
    '<div style="text-align:center;">
        <small style="color:gray;">Вчера (' || d_yesterday || ')</small><br>
        <b style="font-size:20px; color:#666;">' || yesterday_avg_str || ' ₽</b>
    </div>' as "Вчера",
    '<div style="text-align:center;">
        <small style="color:gray;">Изменение</small><br>
        <b style="font-size:20px; color:' || CASE WHEN change_pct >= 0 THEN '#27ae60' ELSE '#e74c3c' END || ';">' 
        || CASE WHEN change_pct >= 0 THEN '▲ ' ELSE '▼ ' END
        || ABS(change_pct) || '%</b>
    </div>' as "Динамика"
FROM final_calc;

-- 3. Количество поездок (сегодня / вчера)
WITH today AS (
    SELECT COALESCE(COUNT(*), 0) as rides_count
    FROM rides
    WHERE DATE(ride_started_at) = CURRENT_DATE
),
yesterday AS (
    SELECT COALESCE(COUNT(*), 0) as rides_count
    FROM rides
    WHERE DATE(ride_started_at) = CURRENT_DATE - 1
),
stats AS (
    SELECT 
        TO_CHAR(t.rides_count, 'FM999G999G999') as today_rides_str,
        TO_CHAR(y.rides_count, 'FM999G999G999') as yesterday_rides_str,
        t.rides_count as t_raw,
        y.rides_count as y_raw,
        TO_CHAR(CURRENT_DATE, 'DD.MM.YY') as d_today,
        TO_CHAR(CURRENT_DATE - 1, 'DD.MM.YY') as d_yesterday
    FROM today t, yesterday y
),
final_calc AS (
    SELECT *,
        CASE 
            WHEN y_raw = 0 THEN 0 
            ELSE ROUND(100.0 * (t_raw - y_raw) / y_raw, 1) 
        END as change_pct
    FROM stats
)
SELECT 
    '<div style="text-align:center;">
        <small style="color:gray;">Сегодня (' || d_today || ')</small><br>
        <b style="font-size:24px;">' || today_rides_str || '</b>
    </div>' as "Сегодня",
    '<div style="text-align:center;">
        <small style="color:gray;">Вчера (' || d_yesterday || ')</small><br>
        <b style="font-size:20px; color:#666;">' || yesterday_rides_str || '</b>
    </div>' as "Вчера",
    '<div style="text-align:center;">
        <small style="color:gray;">Изменение</small><br>
        <b style="font-size:20px; color:' || CASE WHEN change_pct >= 0 THEN '#27ae60' ELSE '#e74c3c' END || ';">' 
        || CASE WHEN change_pct >= 0 THEN '▲ ' ELSE '▼ ' END
        || ABS(change_pct) || '%</b>
    </div>' as "Динамика"
FROM final_calc;

-- 4. Сравнение выручки (сегодня / вчера)
WITH today AS (
    SELECT COALESCE(SUM(ride_price), 0) as revenue
    FROM rides
    WHERE DATE(ride_started_at) = CURRENT_DATE
),
yesterday AS (
    SELECT COALESCE(SUM(ride_price), 0) as revenue
    FROM rides
    WHERE DATE(ride_started_at) = CURRENT_DATE - 1
),
stats AS (
    SELECT 
        TO_CHAR(t.revenue, 'FM999G999G999') as today_rev_str,
        TO_CHAR(y.revenue, 'FM999G999G999') as yesterday_rev_str,
        t.revenue as t_raw,
        y.revenue as y_raw,
        TO_CHAR(CURRENT_DATE, 'DD.MM.YY') as d_today,
        TO_CHAR(CURRENT_DATE - 1, 'DD.MM.YY') as d_yesterday
    FROM today t, yesterday y
),
final_calc AS (
    SELECT *,
        CASE 
            WHEN y_raw = 0 THEN 0 
            ELSE ROUND(100.0 * (t_raw - y_raw) / y_raw, 1) 
        END as change_pct
    FROM stats
)
SELECT 
    '<div style="text-align:center;">
        <small style="color:gray;">Сегодня (' || d_today || ')</small><br>
        <b style="font-size:24px;">' || today_rev_str || ' ₽</b>
    </div>' as "Сегодня",
    '<div style="text-align:center;">
        <small style="color:gray;">Вчера (' || d_yesterday || ')</small><br>
        <b style="font-size:20px; color:#666;">' || yesterday_rev_str || ' ₽</b>
    </div>' as "Вчера",
    '<div style="text-align:center;">
        <small style="color:gray;">Изменение</small><br>
        <b style="font-size:20px; color:' || CASE WHEN change_pct >= 0 THEN '#27ae60' ELSE '#e74c3c' END || ';">' 
        || CASE WHEN change_pct >= 0 THEN '▲ ' ELSE '▼ ' END
        || ABS(change_pct) || '%</b>
    </div>' as "Динамика"
FROM final_calc;

-- 5. Средний чек по дням
SELECT 
    DATE(ride_started_at) as date,
    ROUND(AVG(ride_price), 2) as avg_check
FROM rides
GROUP BY DATE(ride_started_at)
ORDER BY date;

-- 6. Активные водители по дням
SELECT 
    DATE(r.ride_started_at) as date,
    COUNT(DISTINCT o.driver_id) as active_drivers
FROM rides r
JOIN orders o ON r.order_id = o.order_id
GROUP BY DATE(r.ride_started_at)
ORDER BY date;

-- 7. Выручка по дням
SELECT 
    DATE(ride_started_at) as date,
    SUM(ride_price) as revenue
FROM rides
GROUP BY DATE(ride_started_at)
ORDER BY date;

-- 8. Количество поездок по дням
SELECT 
    DATE(ride_started_at) as date,
    COUNT(*) as rides_count
FROM rides
GROUP BY DATE(ride_started_at)
ORDER BY date;

-- 9. Топ-10 водителей по выручке
SELECT 
    RANK() OVER (ORDER BY SUM(r.ride_price) DESC) as "Место",
    '<div style="line-height: 1.2;">
        <b style="font-size: 14px;">' || d.car_brand || ' ' || d.car_model || '</b><br>
        <small style="color: gray;">ID: ' || d.driver_id || ' | Рейтинг: ★' || d.driver_rating || '</small>
    </div>' as "Водитель",
    '<b>' || REPLACE(TO_CHAR(SUM(r.ride_price), 'FM999,999,999'), ',', ' ') || ' ₽</b>' as "Выручка",
    '<div style="background: #eee; width: 100px; height: 8px; border-radius: 4px;">
        <div style="background: #27ae60; width: ' || 
        ROUND(100.0 * SUM(r.ride_price) / FIRST_VALUE(SUM(r.ride_price)) OVER (ORDER BY SUM(r.ride_price) DESC), 0) || 
        '%; height: 100%; border-radius: 4px;"></div>
    </div>' as "Относительно лидера"
FROM rides r
JOIN orders o ON r.order_id = o.order_id
JOIN drivers d ON o.driver_id = d.driver_id
GROUP BY d.driver_id, d.car_brand, d.car_model, d.driver_rating
ORDER BY SUM(r.ride_price) DESC
LIMIT 10;

-- 10. Карта эффективности марок
SELECT 
    d.car_brand as "Марка",
    COUNT(r.ride_id) as "Поездок",
    '<b>' || ROUND(AVG(r.ride_price))::text || ' ₽</b>' as "Средний чек",
    '<div style="background: #eee; width: 100%; height: 15px; border-radius: 3px; position: relative;">
        <div style="background: #3498db; width: ' || 
        ROUND(100.0 * SUM(r.ride_price) / FIRST_VALUE(SUM(r.ride_price)) OVER (ORDER BY SUM(r.ride_price) DESC), 0) || 
        '%; height: 100%; border-radius: 3px;"></div>
        <span style="position: absolute; left: 5px; top: -2px; font-size: 10px; color: #000;">' || 
        REPLACE(TO_CHAR(SUM(r.ride_price), 'FM999,999,999'), ',', ' ') || ' ₽</span>
    </div>' as "Доля в выручке"
FROM rides r
JOIN orders o ON r.order_id = o.order_id
JOIN drivers d ON o.driver_id = d.driver_id
GROUP BY d.car_brand
ORDER BY SUM(r.ride_price) DESC;

-- 11. Распределение типов поездок
SELECT 
    o.order_type,
    COUNT(*) as rides_count
FROM rides r
JOIN orders o ON r.order_id = o.order_id
GROUP BY o.order_type
ORDER BY rides_count DESC;


-- ==============================================
-- ИТОГИ ЗА 2025 ГОД
-- ==============================================

-- 12. Выручка за 2025 год
SELECT SUM(ride_price) as revenue_2025
FROM rides r
JOIN orders o ON r.order_id = o.order_id
WHERE DATE_PART('year', o.created_at) = 2025;

-- 13. Общее количество заказов за 2025 год
SELECT COUNT(*) as total_orders
FROM orders
WHERE DATE_PART('year', created_at) = 2025;

-- 14. Общее количество поездок за 2025 год
SELECT COUNT(*) as total_rides
FROM rides
WHERE DATE_PART('year', ride_started_at) = 2025;

-- 15. DAU за 2025 год
WITH daily_users AS (
    SELECT DATE(created_at) as day, COUNT(DISTINCT user_id) as users
    FROM orders WHERE DATE_PART('year', created_at) = 2025
    GROUP BY DATE(created_at)
)
SELECT ROUND(AVG(users), 0) as dau FROM daily_users;

-- 16. WAU за 2025 год
WITH weekly_users AS (
    SELECT DATE_TRUNC('week', created_at) as week, COUNT(DISTINCT user_id) as users
    FROM orders WHERE DATE_PART('year', created_at) = 2025
    GROUP BY DATE_TRUNC('week', created_at)
)
SELECT ROUND(AVG(users), 0) as wau FROM weekly_users;

-- 17. MAU за 2025 год
WITH monthly_users AS (
    SELECT DATE_TRUNC('month', created_at) as month, COUNT(DISTINCT user_id) as users
    FROM orders WHERE DATE_PART('year', created_at) = 2025
    GROUP BY DATE_TRUNC('month', created_at)
)
SELECT ROUND(AVG(users), 0) as mau FROM monthly_users;

-- 18. LTV за 2025 год
SELECT 
    ROUND(SUM(ride_price) / NULLIF(COUNT(DISTINCT o.user_id), 0), 2) as ltv
FROM rides r
JOIN orders o ON r.order_id = o.order_id
WHERE DATE_PART('year', r.ride_started_at) = 2025;

-- 19. Количество уникальных водителей за 2025 год
SELECT COUNT(DISTINCT o.driver_id) as unique_drivers
FROM rides r
JOIN orders o ON r.order_id = o.order_id
WHERE DATE_PART('year', r.ride_started_at) = 2025;

-- 20. Средняя сумма заказа за 2025 год
SELECT AVG(ride_price) as avg_order_value
FROM rides
WHERE DATE_PART('year', ride_started_at) = 2025;

-- 21. Выручка по дням за 2025 год
SELECT 
    DATE(ride_started_at) as date,
    SUM(ride_price) as revenue
FROM rides
WHERE DATE_PART('year', ride_started_at) = 2025
GROUP BY DATE(ride_started_at)
ORDER BY date;

-- 22. Количество поездок по дням за 2025 год
SELECT 
    DATE(ride_started_at) as date,
    COUNT(*) as rides_count
FROM rides
WHERE DATE_PART('year', ride_started_at) = 2025
GROUP BY DATE(ride_started_at)
ORDER BY date;

-- 23. Средний чек по дням за 2025 год
SELECT 
    DATE(ride_started_at) as date,
    ROUND(AVG(ride_price), 2) as avg_check
FROM rides
WHERE DATE_PART('year', ride_started_at) = 2025
GROUP BY DATE(ride_started_at)
ORDER BY date;

-- 24. Активные водители по дням за 2025 год
SELECT 
    DATE(r.ride_started_at) as date,
    COUNT(DISTINCT o.driver_id) as active_drivers
FROM rides r
JOIN orders o ON r.order_id = o.order_id
WHERE DATE_PART('year', r.ride_started_at) = 2025
GROUP BY DATE(r.ride_started_at)
ORDER BY date;

-- 25. Топ-10 водителей по выручке за 2025 год
SELECT 
    RANK() OVER (ORDER BY SUM(r.ride_price) DESC) as "Место",
    '<div style="line-height: 1.2;">
        <b style="font-size: 14px;">' || d.car_brand || ' ' || d.car_model || '</b><br>
        <small style="color: gray;">ID: ' || d.driver_id || ' | Рейтинг: ★' || d.driver_rating || '</small>
    </div>' as "Водитель",
    '<b>' || REPLACE(TO_CHAR(SUM(r.ride_price), 'FM999,999,999'), ',', ' ') || ' ₽</b>' as "Выручка",
    '<div style="background: #eee; width: 100px; height: 8px; border-radius: 4px;">
        <div style="background: #27ae60; width: ' || 
        ROUND(100.0 * SUM(r.ride_price) / FIRST_VALUE(SUM(r.ride_price)) OVER (ORDER BY SUM(r.ride_price) DESC), 0) || 
        '%; height: 100%; border-radius: 4px;"></div>
    </div>' as "Относительно лидера"
FROM rides r
JOIN orders o ON r.order_id = o.order_id
JOIN drivers d ON o.driver_id = d.driver_id
WHERE DATE_PART('year', r.ride_started_at) = 2025
GROUP BY d.driver_id, d.car_brand, d.car_model, d.driver_rating
ORDER BY SUM(r.ride_price) DESC
LIMIT 10;

-- 26. Распределение типов поездок за 2025 год
SELECT 
    o.order_type,
    COUNT(*) as rides_count
FROM rides r
JOIN orders o ON r.order_id = o.order_id
WHERE DATE_PART('year', r.ride_started_at) = 2025
GROUP BY o.order_type
ORDER BY rides_count DESC;

-- 27. Когортная матрица (Retention) за 2025 год
WITH first_order AS (
    SELECT 
        user_id,
        DATE_TRUNC('month', MIN(created_at)) as cohort_month
    FROM orders
    WHERE DATE_PART('year', created_at) = 2025
    GROUP BY user_id
),
cohort_activity AS (
    SELECT 
        f.cohort_month,
        DATE_TRUNC('month', r.ride_started_at) as activity_month,
        COUNT(DISTINCT o.user_id) as users
    FROM first_order f
    JOIN orders o ON f.user_id = o.user_id
    JOIN rides r ON o.order_id = r.order_id
    GROUP BY f.cohort_month, activity_month
),
cohort_size AS (
    SELECT 
        cohort_month,
        users as total_users
    FROM cohort_activity
    WHERE cohort_month = activity_month
),
retention_data AS (
    SELECT 
        c.cohort_month,
        (EXTRACT(YEAR FROM c.activity_month) * 12 + EXTRACT(MONTH FROM c.activity_month))
        - (EXTRACT(YEAR FROM c.cohort_month) * 12 + EXTRACT(MONTH FROM c.cohort_month)) as stage,
        ROUND(100.0 * c.users / s.total_users, 2) as retention_pct
    FROM cohort_activity c
    JOIN cohort_size s ON c.cohort_month = s.cohort_month
    WHERE c.activity_month >= c.cohort_month
)
SELECT 
    TO_CHAR(cohort_month, 'Mon YYYY') as "Cohort",
    MAX(CASE WHEN stage = 0 THEN retention_pct ELSE 0 END) AS "M0",
    MAX(CASE WHEN stage = 1 THEN retention_pct ELSE 0 END) AS "M1",
    MAX(CASE WHEN stage = 2 THEN retention_pct ELSE 0 END) AS "M2",
    MAX(CASE WHEN stage = 3 THEN retention_pct ELSE 0 END) AS "M3",
    MAX(CASE WHEN stage = 4 THEN retention_pct ELSE 0 END) AS "M4",
    MAX(CASE WHEN stage = 5 THEN retention_pct ELSE 0 END) AS "M5",
    MAX(CASE WHEN stage = 6 THEN retention_pct ELSE 0 END) AS "M6",
    MAX(CASE WHEN stage = 7 THEN retention_pct ELSE 0 END) AS "M7",
    MAX(CASE WHEN stage = 8 THEN retention_pct ELSE 0 END) AS "M8",
    MAX(CASE WHEN stage = 9 THEN retention_pct ELSE 0 END) AS "M9",
    MAX(CASE WHEN stage = 10 THEN retention_pct ELSE 0 END) AS "M10",
    MAX(CASE WHEN stage = 11 THEN retention_pct ELSE 0 END) AS "M11",
    MAX(CASE WHEN stage = 12 THEN retention_pct ELSE 0 END) AS "M12"
FROM retention_data
WHERE stage BETWEEN 0 AND 12
GROUP BY cohort_month
ORDER BY cohort_month;

-- 28. Карта эффективности марок за 2025 год
SELECT 
    d.car_brand as "Марка",
    COUNT(r.ride_id) as "Поездок",
    '<b>' || ROUND(AVG(r.ride_price))::text || ' ₽</b>' as "Средний чек",
    '<div style="background: #eee; width: 100%; height: 15px; border-radius: 3px; position: relative;">
        <div style="background: #3498db; width: ' || 
        ROUND(100.0 * SUM(r.ride_price) / FIRST_VALUE(SUM(r.ride_price)) OVER (ORDER BY SUM(r.ride_price) DESC), 0) || 
        '%; height: 100%; border-radius: 3px;"></div>
        <span style="position: absolute; left: 5px; top: -2px; font-size: 10px; color: #000;">' || 
        REPLACE(TO_CHAR(SUM(r.ride_price), 'FM999,999,999'), ',', ' ') || ' ₽</span>
    </div>' as "Доля в выручке"
FROM rides r
JOIN orders o ON r.order_id = o.order_id
JOIN drivers d ON o.driver_id = d.driver_id
WHERE DATE_PART('year', r.ride_started_at) = 2025
GROUP BY d.car_brand
ORDER BY SUM(r.ride_price) DESC;


-- ==============================================
-- ИТОГИ ЗА 2026 ГОД (январь–апрель)
-- ==============================================

-- 29. Выручка за 2026 год
SELECT SUM(ride_price) as revenue_2026
FROM rides r
JOIN orders o ON r.order_id = o.order_id
WHERE DATE_PART('year', o.created_at) = 2026;

-- 30. Общее количество заказов за 2026 год
SELECT COUNT(*) as total_orders
FROM orders
WHERE DATE_PART('year', created_at) = 2026;

-- 31. Общее количество поездок за 2026 год
SELECT COUNT(*) as total_rides
FROM rides
WHERE DATE_PART('year', ride_started_at) = 2026;

-- 32. DAU за 2026 год
WITH daily_users AS (
    SELECT DATE(created_at) as day, COUNT(DISTINCT user_id) as users
    FROM orders WHERE DATE_PART('year', created_at) = 2026
    GROUP BY DATE(created_at)
)
SELECT ROUND(AVG(users), 0) as dau FROM daily_users;

-- 33. WAU за 2026 год
WITH weekly_users AS (
    SELECT DATE_TRUNC('week', created_at) as week, COUNT(DISTINCT user_id) as users
    FROM orders WHERE DATE_PART('year', created_at) = 2026
    GROUP BY DATE_TRUNC('week', created_at)
)
SELECT ROUND(AVG(users), 0) as wau FROM weekly_users;

-- 34. MAU за 2026 год
WITH monthly_users AS (
    SELECT DATE_TRUNC('month', created_at) as month, COUNT(DISTINCT user_id) as users
    FROM orders WHERE DATE_PART('year', created_at) = 2026
    GROUP BY DATE_TRUNC('month', created_at)
)
SELECT ROUND(AVG(users), 0) as mau FROM monthly_users;

-- 35. LTV за 2026 год
SELECT 
    ROUND(SUM(ride_price) / NULLIF(COUNT(DISTINCT o.user_id), 0), 2) as ltv
FROM rides r
JOIN orders o ON r.order_id = o.order_id
WHERE DATE_PART('year', r.ride_started_at) = 2026;

-- 36. Количество уникальных водителей за 2026 год
SELECT COUNT(DISTINCT o.driver_id) as unique_drivers
FROM rides r
JOIN orders o ON r.order_id = o.order_id
WHERE DATE_PART('year', r.ride_started_at) = 2026;

-- 37. Средняя сумма заказа за 2026 год
SELECT AVG(ride_price) as avg_order_value
FROM rides
WHERE DATE_PART('year', ride_started_at) = 2026;

-- 38. Выручка по дням за 2026 год
SELECT 
    DATE(ride_started_at) as date,
    SUM(ride_price) as revenue
FROM rides
WHERE DATE_PART('year', ride_started_at) = 2026
GROUP BY DATE(ride_started_at)
ORDER BY date;

-- 39. Количество поездок по дням за 2026 год
SELECT 
    DATE(ride_started_at) as date,
    COUNT(*) as rides_count
FROM rides
WHERE DATE_PART('year', ride_started_at) = 2026
GROUP BY DATE(ride_started_at)
ORDER BY date;

-- 40. Средний чек по дням за 2026 год
SELECT 
    DATE(ride_started_at) as date,
    ROUND(AVG(ride_price), 2) as avg_check
FROM rides
WHERE DATE_PART('year', ride_started_at) = 2026
GROUP BY DATE(ride_started_at)
ORDER BY date;

-- 41. Активные водители по дням за 2026 год
SELECT 
    DATE(r.ride_started_at) as date,
    COUNT(DISTINCT o.driver_id) as active_drivers
FROM rides r
JOIN orders o ON r.order_id = o.order_id
WHERE DATE_PART('year', r.ride_started_at) = 2026
GROUP BY DATE(r.ride_started_at)
ORDER BY date;

-- 42. Топ-10 водителей по выручке за 2026 год
SELECT 
    RANK() OVER (ORDER BY SUM(r.ride_price) DESC) as "Место",
    '<div style="line-height: 1.2;">
        <b style="font-size: 14px;">' || d.car_brand || ' ' || d.car_model || '</b><br>
        <small style="color: gray;">ID: ' || d.driver_id || ' | Рейтинг: ★' || d.driver_rating || '</small>
    </div>' as "Водитель",
    '<b>' || REPLACE(TO_CHAR(SUM(r.ride_price), 'FM999,999,999'), ',', ' ') || ' ₽</b>' as "Выручка",
    '<div style="background: #eee; width: 100px; height: 8px; border-radius: 4px;">
        <div style="background: #27ae60; width: ' || 
        ROUND(100.0 * SUM(r.ride_price) / FIRST_VALUE(SUM(r.ride_price)) OVER (ORDER BY SUM(r.ride_price) DESC), 0) || 
        '%; height: 100%; border-radius: 4px;"></div>
    </div>' as "Относительно лидера"
FROM rides r
JOIN orders o ON r.order_id = o.order_id
JOIN drivers d ON o.driver_id = d.driver_id
WHERE DATE_PART('year', r.ride_started_at) = 2026
GROUP BY d.driver_id, d.car_brand, d.car_model, d.driver_rating
ORDER BY SUM(r.ride_price) DESC
LIMIT 10;

-- 43. Распределение типов поездок за 2026 год
SELECT 
    o.order_type,
    COUNT(*) as rides_count
FROM rides r
JOIN orders o ON r.order_id = o.order_id
WHERE DATE_PART('year', r.ride_started_at) = 2026
GROUP BY o.order_type
ORDER BY rides_count DESC;

-- 44. Карта эффективности марок за 2026 год
SELECT 
    d.car_brand as "Марка",
    COUNT(r.ride_id) as "Поездок",
    '<b>' || ROUND(AVG(r.ride_price))::text || ' ₽</b>' as "Средний чек",
    '<div style="background: #eee; width: 100%; height: 15px; border-radius: 3px; position: relative;">
        <div style="background: #3498db; width: ' || 
        ROUND(100.0 * SUM(r.ride_price) / FIRST_VALUE(SUM(r.ride_price)) OVER (ORDER BY SUM(r.ride_price) DESC), 0) || 
        '%; height: 100%; border-radius: 3px;"></div>
        <span style="position: absolute; left: 5px; top: -2px; font-size: 10px; color: #000;">' || 
        REPLACE(TO_CHAR(SUM(r.ride_price), 'FM999,999,999'), ',', ' ') || ' ₽</span>
    </div>' as "Доля в выручке"
FROM rides r
JOIN orders o ON r.order_id = o.order_id
JOIN drivers d ON o.driver_id = d.driver_id
WHERE DATE_PART('year', r.ride_started_at) = 2026
GROUP BY d.car_brand
ORDER BY SUM(r.ride_price) DESC;