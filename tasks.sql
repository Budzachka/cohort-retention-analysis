/* 1
 * Бере користувачів із cohort_users_raw і приводить signup_datetime до єдиного формату дати. Прибирає пробіли та час, замінює роздільники (. / -) на -, доповнює день і місяць нулями (LPAD), дворозрядний рік перетворює на чотирирозрядний. Якщо рядок не відповідає шаблону дати, результат буде NULL. 
   Підсумок: чиста колонка signup_datetime_cleaned.
 */
WITH cleaned_cohort_users AS (
    SELECT 
        user_id,
        full_name,
        email,
        country,
        signup_source,
        signup_device,
        promo_signup_flag,
        CASE 
            WHEN TRIM(SPLIT_PART(signup_datetime, ' ', 1)) ~ '^\d{1,2}[./-]\d{1,2}[./-]\d{2,4}$' THEN
                TO_DATE(
                    LPAD(SPLIT_PART(REGEXP_REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '[./-]', '-', 'g'), '-', 1), 2, '0') || '-' ||
                    LPAD(SPLIT_PART(REGEXP_REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '[./-]', '-', 'g'), '-', 2), 2, '0') || '-' ||
                    CASE 
                        WHEN LENGTH(SPLIT_PART(REGEXP_REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '[./-]', '-', 'g'), '-', 3)) = 2 
                        THEN '20' || SPLIT_PART(REGEXP_REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '[./-]', '-', 'g'), '-', 3)
                        ELSE SPLIT_PART(REGEXP_REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '[./-]', '-', 'g'), '-', 3)
                    END,
                    'DD-MM-YYYY'
                )::DATE
            ELSE NULL
        END AS signup_datetime_cleaned
    FROM cohort_users_raw
)
SELECT 
    user_id,
    full_name,
    email,
    country,
    signup_datetime_cleaned,
    signup_source,
    signup_device,
    promo_signup_flag
FROM cleaned_cohort_users;
/*2
 * Те саме для іншої колонки.
 */
WITH cleaned_cohort_events AS (
    SELECT 
        event_id,
        user_id,
        event_type,
        revenue,
        TRIM(SPLIT_PART(event_datetime, ' ', 1)) AS date_only_str
    FROM cohort_events_raw
),
processed_events AS (
    SELECT 
        event_id,
        user_id,
        event_type,
        revenue,
        CASE 
            WHEN date_only_str ~ '^\d{1,2}[./-]\d{1,2}[./-]\d{2,4}$' THEN
                TO_DATE(
                    LPAD(SPLIT_PART(REPLACE(REPLACE(date_only_str, '.', '-'), '/', '-'), '-', 1), 2, '0') || '-' ||
                    LPAD(SPLIT_PART(REPLACE(REPLACE(date_only_str, '.', '-'), '/', '-'), '-', 2), 2, '0') || '-' ||
                    CASE 
                        WHEN LENGTH(SPLIT_PART(REPLACE(REPLACE(date_only_str, '.', '-'), '/', '-'), '-', 3)) = 2 
                        THEN '20' || SPLIT_PART(REPLACE(REPLACE(date_only_str, '.', '-'), '/', '-'), '-', 3)
                        ELSE SPLIT_PART(REPLACE(REPLACE(date_only_str, '.', '-'), '/', '-'), '-', 3)
                    END,
                    'DD-MM-YYYY'
                )::DATE 
            ELSE NULL
        END AS event_datetime_cleaned
    FROM cleaned_cohort_events
)
SELECT 
    event_id,
    user_id,
    event_datetime_cleaned,
    event_type,
    revenue
FROM processed_events;
/*3
 * Об'єднує очищених користувачів і події через JOIN по user_id. Дати переводить у формат рік-місяць (когорта реєстрації та місяць події) і рахує month_offset: різницю в місяцях між подією та реєстрацією, тобто «стаж» користувача. 
   Фільтрує сміття: немає дати реєстрації чи події, немає типу події, тестові події (test_event).
 */
WITH cleaned_cohort_users AS (
    SELECT 
        user_id,
        full_name,
        email,
        country,
        signup_source,
        signup_device,
        promo_signup_flag,
        CASE 
            WHEN TRIM(SPLIT_PART(signup_datetime, ' ', 1)) ~ '^\d{1,2}[./-]\d{1,2}[./-]\d{2,4}$' THEN
                TO_DATE(
                    LPAD(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 1), 2, '0') || '-' ||
                    LPAD(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 2), 2, '0') || '-' ||
                    CASE 
                        WHEN LENGTH(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)) = 2 
                        THEN '20' || SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)
                        ELSE SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)
                    END,
                    'DD-MM-YYYY'
                )::DATE
            ELSE NULL
        END AS signup_date_cleaned
    FROM cohort_users_raw
),
cleaned_cohort_events AS (
    SELECT 
        event_id,
        user_id,
        event_type,
        revenue,
        CASE 
            WHEN TRIM(SPLIT_PART(event_datetime, ' ', 1)) ~ '^\d{1,2}[./-]\d{1,2}[./-]\d{2,4}$' THEN
                TO_DATE(
                    LPAD(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 1), 2, '0') || '-' ||
                    LPAD(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 2), 2, '0') || '-' ||
                    CASE 
                        WHEN LENGTH(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)) = 2 
                        THEN '20' || SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)
                        ELSE SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)
                    END,
                    'DD-MM-YYYY'
                )::DATE
            ELSE NULL
        END AS event_date_cleaned
    FROM cohort_events_raw
)
SELECT 
    u.user_id,
    u.full_name,
    u.country,
    TO_CHAR(u.signup_date_cleaned, 'YYYY-MM') AS signup_cohort,
    TO_CHAR(e.event_date_cleaned, 'YYYY-MM') AS event_month,
    e.event_type,
    e.revenue,
    (EXTRACT(YEAR FROM e.event_date_cleaned) - EXTRACT(YEAR FROM u.signup_date_cleaned)) * 12 +
    (EXTRACT(MONTH FROM e.event_date_cleaned) - EXTRACT(MONTH FROM u.signup_date_cleaned)) AS month_offset
FROM cleaned_cohort_users u
INNER JOIN cleaned_cohort_events e ON u.user_id = e.user_id
WHERE u.signup_date_cleaned IS NOT NULL
  AND e.event_date_cleaned IS NOT NULL
  AND e.event_type IS NOT NULL
  AND e.event_type != 'test_event';
/*4
 * Будує таблицю для Google Sheets. Групує за promo_signup_flag, cohort_month і month_offset та рахує users_total, тобто унікальних активних користувачів. 
   Обмежує період активності січнем-червнем 2025 і сортує за групою, когортою та зсувом.
 */
WITH cleaned_cohort_users AS (
    SELECT 
        user_id,
        promo_signup_flag,
        CASE 
            WHEN TRIM(SPLIT_PART(signup_datetime, ' ', 1)) ~ '^\d{1,2}[./-]\d{1,2}[./-]\d{2,4}$' THEN
                TO_DATE(
                    LPAD(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 1), 2, '0') || '-' ||
                    LPAD(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 2), 2, '0') || '-' ||
                    CASE 
                        WHEN LENGTH(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)) = 2 
                        THEN '20' || SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)
                        ELSE SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(signup_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)
                    END,
                    'DD-MM-YYYY'
                )::DATE
            ELSE NULL
        END AS signup_date_cleaned
    FROM cohort_users_raw
),
cleaned_cohort_events AS (
    SELECT 
        user_id,
        event_type,
        CASE 
            WHEN TRIM(SPLIT_PART(event_datetime, ' ', 1)) ~ '^\d{1,2}[./-]\d{1,2}[./-]\d{2,4}$' THEN
                TO_DATE(
                    LPAD(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 1), 2, '0') || '-' ||
                    LPAD(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 2), 2, '0') || '-' ||
                    CASE 
                        WHEN LENGTH(SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)) = 2 
                        THEN '20' || SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)
                        ELSE SPLIT_PART(REPLACE(REPLACE(TRIM(SPLIT_PART(event_datetime, ' ', 1)), '.', '-'), '/', '-'), '-', 3)
                    END,
                    'DD-MM-YYYY'
                )::DATE
            ELSE NULL
        END AS event_date_cleaned
    FROM cohort_events_raw
),
joined_data AS (
    SELECT 
        u.promo_signup_flag,
        DATE_TRUNC('month', u.signup_date_cleaned)::DATE AS cohort_month,
        u.user_id,
        (EXTRACT(YEAR FROM e.event_date_cleaned) - EXTRACT(YEAR FROM u.signup_date_cleaned)) * 12 +
        (EXTRACT(MONTH FROM e.event_date_cleaned) - EXTRACT(MONTH FROM u.signup_date_cleaned)) AS month_offset
    FROM cleaned_cohort_users u
    INNER JOIN cleaned_cohort_events e ON u.user_id = e.user_id
    WHERE u.signup_date_cleaned IS NOT NULL
      AND e.event_date_cleaned IS NOT NULL
      AND e.event_type IS NOT NULL
      AND e.event_type != 'test_event'
      AND e.event_date_cleaned >= '2025-01-01'
      AND e.event_date_cleaned <= '2025-06-30'
)
SELECT 
    promo_signup_flag,
    cohort_month,
    month_offset,
    COUNT(DISTINCT user_id) AS users_total 
FROM joined_data
GROUP BY 
    promo_signup_flag,
    cohort_month,
    month_offset
ORDER BY 
    promo_signup_flag,   
    cohort_month,         
    month_offset;         
