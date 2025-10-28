-- DAT3_Details_Optimized.sql
-- Performance-optimized version of the hotel data mart query
-- Key optimizations:
-- 1. Reduced CTE complexity
-- 2. Optimized currency conversion
-- 3. Improved filtering logic
-- 4. Better join strategies

-- Parameters (same as original)
-- :p_start_date, :p_end_date, :p_property_ids, :p_property_all, etc.

WITH
-- Simplified params CTE with computed values
params AS (
    SELECT
        :p_start_date::date AS start_date,
        :p_end_date::date AS end_date,
        :p_property_ids::int[] AS property_ids,
        COALESCE(:p_property_all::boolean, FALSE) AS property_all,
        :p_brand_ids::int[] AS brand_ids,
        COALESCE(:p_brand_all::boolean, FALSE) AS brand_all,
        :p_region_ids::int[] AS region_ids,
        COALESCE(:p_region_all::boolean, FALSE) AS region_all,
        :p_market_ids::int[] AS market_ids,
        COALESCE(:p_market_all::boolean, FALSE) AS market_all,
        :p_owner_ids::int[] AS owner_ids,
        COALESCE(:p_owner_all::boolean, FALSE) AS owner_all,
        :p_management_types::text[] AS mgmt_types,
        COALESCE(:p_management_all::boolean, FALSE) AS mgmt_all,
        :p_room_category_ids::int[] AS room_category_ids,
        :p_channel_ids::int[] AS channel_ids,
        :p_loyalty_levels::text[] AS loyalty_levels,
        :p_booking_window_from::int AS booking_window_from,
        :p_booking_window_to::int AS booking_window_to,
        :p_rate_plan_ids::int[] AS rate_plan_ids,
        :p_intermediary_ids::int[] AS intermediary_ids,
        :p_trip_purposes::text[] AS trip_purposes,
        :p_wholesaler_ids::int[] AS wholesaler_ids,
        :p_currency_base::text AS currency_base,
        -- Column visibility flags
        COALESCE(:p_show_property::boolean, FALSE) AS show_property,
        COALESCE(:p_show_brand::boolean, FALSE) AS show_brand,
        COALESCE(:p_show_region::boolean, FALSE) AS show_region,
        COALESCE(:p_show_market::boolean, FALSE) AS show_market,
        COALESCE(:p_show_owner::boolean, FALSE) AS show_owner,
        COALESCE(:p_show_mgmt_type::boolean, FALSE) AS show_mgmt_type,
        COALESCE(:p_show_room_category::boolean, FALSE) AS show_room_category,
        COALESCE(:p_show_channel::boolean, FALSE) AS show_channel,
        COALESCE(:p_show_loyalty::boolean, FALSE) AS show_loyalty,
        COALESCE(:p_show_rate_plan::boolean, FALSE) AS show_rate_plan,
        COALESCE(:p_show_intermediary::boolean, FALSE) AS show_intermediary,
        COALESCE(:p_show_trip_purpose::boolean, FALSE) AS show_trip_purpose,
        COALESCE(:p_show_wholesaler::boolean, FALSE) AS show_wholesaler,
        COALESCE(:p_show_booking_date::boolean, TRUE) AS show_booking_date,
        -- Pre-computed values for performance
        CASE WHEN :p_booking_window_from IS NOT NULL AND :p_booking_window_to IS NOT NULL 
             THEN TRUE ELSE FALSE END AS has_booking_window_filter,
        CASE WHEN :p_room_category_ids IS NOT NULL AND array_length(:p_room_category_ids,1) > 0 
             THEN TRUE ELSE FALSE END AS has_room_category_filter,
        CASE WHEN :p_channel_ids IS NOT NULL AND array_length(:p_channel_ids,1) > 0 
             THEN TRUE ELSE FALSE END AS has_channel_filter,
        CASE WHEN :p_loyalty_levels IS NOT NULL AND array_length(:p_loyalty_levels,1) > 0 
             THEN TRUE ELSE FALSE END AS has_loyalty_filter,
        CASE WHEN :p_rate_plan_ids IS NOT NULL AND array_length(:p_rate_plan_ids,1) > 0 
             THEN TRUE ELSE FALSE END AS has_rate_plan_filter,
        CASE WHEN :p_intermediary_ids IS NOT NULL AND array_length(:p_intermediary_ids,1) > 0 
             THEN TRUE ELSE FALSE END AS has_intermediary_filter,
        CASE WHEN :p_trip_purposes IS NOT NULL AND array_length(:p_trip_purposes,1) > 0 
             THEN TRUE ELSE FALSE END AS has_trip_purpose_filter,
        CASE WHEN :p_wholesaler_ids IS NOT NULL AND array_length(:p_wholesaler_ids,1) > 0 
             THEN TRUE ELSE FALSE END AS has_wholesaler_filter
),

-- Optimized property dimension with pre-filtering
property_dim AS (
    SELECT
        p.property_id,
        p.property_name,
        b.brand_id,
        b.brand_name,
        r.region_id,
        r.region_name,
        mkt.market_id,
        mkt.market_name,
        o.owner_id,
        o.owner_name,
        CASE p.management_type 
            WHEN 'M' THEN 'Managed'
            WHEN 'F' THEN 'Franchised'
            ELSE p.management_type
        END AS management_type,
        COALESCE(p.currency_code, 'USD') AS property_currency,
        p.rooms_total
    FROM properties p
    LEFT JOIN brands b ON p.brand_id = b.brand_id
    LEFT JOIN regions r ON p.region_id = r.region_id
    LEFT JOIN markets mkt ON p.market_id = mkt.market_id
    LEFT JOIN owners o ON p.owner_id = o.owner_id
    -- Apply property-level filters early
    CROSS JOIN params prm
    WHERE (
        prm.property_all
        OR (prm.property_ids IS NOT NULL AND array_length(prm.property_ids,1) > 0 AND p.property_id = ANY(prm.property_ids))
    )
    AND (
        prm.brand_all
        OR (prm.brand_ids IS NOT NULL AND array_length(prm.brand_ids,1) > 0 AND p.brand_id = ANY(prm.brand_ids))
    )
    AND (
        prm.region_all
        OR (prm.region_ids IS NOT NULL AND array_length(prm.region_ids,1) > 0 AND p.region_id = ANY(prm.region_ids))
    )
    AND (
        prm.market_all
        OR (prm.market_ids IS NOT NULL AND array_length(prm.market_ids,1) > 0 AND p.market_id = ANY(prm.market_ids))
    )
    AND (
        prm.owner_all
        OR (prm.owner_ids IS NOT NULL AND array_length(prm.owner_ids,1) > 0 AND p.owner_id = ANY(prm.owner_ids))
    )
    AND (
        prm.mgmt_all
        OR (prm.mgmt_types IS NOT NULL AND array_length(prm.mgmt_types,1) > 0 AND 
            CASE p.management_type 
                WHEN 'M' THEN 'Managed'
                WHEN 'F' THEN 'Franchised'
                ELSE p.management_type
            END = ANY(prm.mgmt_types))
    )
),

-- Optimized capacity calculation (avoid CROSS JOIN)
capacity_agg AS (
    SELECT
        pd.property_id,
        pd.rooms_total AS total_rooms,
        EXTRACT(DAY FROM (prm.end_date - prm.start_date + INTERVAL '1 day'))::int AS days_in_range,
        pd.rooms_total * EXTRACT(DAY FROM (prm.end_date - prm.start_date + INTERVAL '1 day'))::int AS total_room_nights
    FROM property_dim pd
    CROSS JOIN params prm
),

-- Pre-computed currency rates for better performance
currency_rates_lookup AS (
    SELECT DISTINCT ON (cr.currency_code)
        cr.currency_code,
        cr.rate_to_base,
        cr.rate_date
    FROM currency_rates cr
    CROSS JOIN params prm
    WHERE cr.base_currency = prm.currency_base
      AND cr.rate_date <= prm.end_date
    ORDER BY cr.currency_code, cr.rate_date DESC
),

-- Optimized bookings fact with early filtering
bookings_fact AS (
    SELECT 
        bf.*,
        pd.property_name,
        pd.brand_id,
        pd.brand_name,
        pd.region_id,
        pd.region_name,
        pd.market_id,
        pd.market_name,
        pd.owner_id,
        pd.owner_name,
        pd.management_type,
        pd.property_currency,
        ca.total_rooms,
        ca.days_in_range,
        ca.total_room_nights,
        COALESCE(crl.rate_to_base, 1.0) AS rate_to_base
    FROM bookings bf
    INNER JOIN property_dim pd ON bf.property_id = pd.property_id
    INNER JOIN capacity_agg ca ON pd.property_id = ca.property_id
    LEFT JOIN currency_rates_lookup crl ON crl.currency_code = COALESCE(bf.currency_code, pd.property_currency)
    CROSS JOIN params prm
    WHERE bf.checkin_date <= prm.end_date
      AND bf.checkout_date > prm.start_date
      -- Apply remaining filters
      AND (
          NOT prm.has_room_category_filter 
          OR bf.room_category_id = ANY(prm.room_category_ids)
      )
      AND (
          NOT prm.has_channel_filter 
          OR bf.channel_id = ANY(prm.channel_ids)
      )
      AND (
          NOT prm.has_loyalty_filter 
          OR bf.loyalty_level = ANY(prm.loyalty_levels)
      )
      AND (
          NOT prm.has_rate_plan_filter 
          OR bf.rate_plan_id = ANY(prm.rate_plan_ids)
      )
      AND (
          NOT prm.has_intermediary_filter 
          OR bf.intermediary_id = ANY(prm.intermediary_ids)
      )
      AND (
          NOT prm.has_trip_purpose_filter 
          OR bf.trip_purpose = ANY(prm.trip_purposes)
      )
      AND (
          NOT prm.has_wholesaler_filter 
          OR bf.wholesaler_id = ANY(prm.wholesaler_ids)
      )
      AND (
          NOT prm.has_booking_window_filter
          OR (
              (prm.booking_window_from IS NULL OR (bf.checkin_date::date - bf.booking_date::date) >= prm.booking_window_from)
              AND (prm.booking_window_to IS NULL OR (bf.checkin_date::date - bf.booking_date::date) <= prm.booking_window_to)
          )
      )
)

-- Final optimized select
SELECT
    -- Dimension columns (optimized CASE statements)
    CASE WHEN prm.show_property THEN bf.property_name END AS property_name,
    CASE WHEN prm.show_brand THEN bf.brand_name END AS brand_name,
    CASE WHEN prm.show_region THEN bf.region_name END AS region_name,
    CASE WHEN prm.show_market THEN bf.market_name END AS market_name,
    CASE WHEN prm.show_owner THEN bf.owner_name END AS owner_name,
    CASE WHEN prm.show_mgmt_type THEN bf.management_type END AS management_type,
    CASE WHEN prm.show_room_category THEN rc.category_name END AS room_category,
    CASE WHEN prm.show_channel THEN ch.channel_name END AS channel_name,
    CASE WHEN prm.show_loyalty THEN bf.loyalty_level END AS loyalty_level,
    CASE WHEN prm.show_rate_plan THEN rp.rate_plan_name END AS rate_plan_name,
    CASE WHEN prm.show_intermediary THEN i.intermediary_name END AS intermediary_name,
    CASE WHEN prm.show_trip_purpose THEN bf.trip_purpose END AS trip_purpose,
    CASE WHEN prm.show_wholesaler THEN w.wholesaler_name END AS wholesaler_name,
    CASE WHEN prm.show_booking_date THEN bf.booking_date END AS booking_date,

    -- Date fields
    bf.checkin_date,
    bf.checkout_date,

    -- Derived metrics (optimized calculations)
    GREATEST((bf.checkout_date::date - bf.checkin_date::date), 0) AS stay_nights,

    -- Original currency amounts
    bf.room_revenue AS room_revenue_original,
    bf.addon_revenue AS addon_revenue_original,
    bf.package_revenue AS package_revenue_original,
    bf.fee_amount AS fee_amount_original,
    bf.tax_amount AS tax_amount_original,
    bf.currency_code AS booking_currency,

    -- Converted amounts (optimized rounding)
    ROUND(bf.room_revenue * bf.rate_to_base, 2) AS room_revenue_base,
    ROUND(bf.addon_revenue * bf.rate_to_base, 2) AS addon_revenue_base,
    ROUND(bf.package_revenue * bf.rate_to_base, 2) AS package_revenue_base,
    ROUND(bf.fee_amount * bf.rate_to_base, 2) AS fee_amount_base,
    ROUND(bf.tax_amount * bf.rate_to_base, 2) AS tax_amount_base,

    -- Aggregated metrics
    ROUND((bf.room_revenue + bf.addon_revenue + bf.package_revenue) * bf.rate_to_base, 2) AS total_revenue_base,

    -- Capacity metrics
    bf.total_rooms,
    bf.days_in_range,
    bf.total_room_nights,

    -- Occupancy calculations
    GREATEST((bf.checkout_date::date - bf.checkin_date::date), 0) AS room_nights_sold,
    CASE WHEN bf.total_room_nights > 0
         THEN ROUND((GREATEST((bf.checkout_date::date - bf.checkin_date::date), 0)::numeric / bf.total_room_nights) * 100, 4)
         ELSE NULL END AS occupancy_pct

FROM bookings_fact bf
-- Optimized joins (only when needed)
LEFT JOIN room_categories rc ON prm.show_room_category AND bf.room_category_id = rc.room_category_id
LEFT JOIN channels ch ON prm.show_channel AND bf.channel_id = ch.channel_id
LEFT JOIN rate_plans rp ON prm.show_rate_plan AND bf.rate_plan_id = rp.rate_plan_id
LEFT JOIN intermediaries i ON prm.show_intermediary AND bf.intermediary_id = i.intermediary_id
LEFT JOIN wholesalers w ON prm.show_wholesaler AND bf.wholesaler_id = w.wholesaler_id
CROSS JOIN params prm

ORDER BY
    COALESCE(bf.property_name, bf.property_id),
    bf.booking_date;

-- End of optimized query