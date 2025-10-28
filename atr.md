# Account Tracking Report (ATR)

## Overview
The Account Tracking Report (ATR) is a comprehensive PostgreSQL query designed for hotel revenue management and analytics. It provides detailed booking and revenue data with multi-dimensional filtering capabilities and dynamic column inclusion.

## Purpose
This report serves as a data mart template for hotel operations, enabling:
- Multi-dimensional analysis of hotel bookings and revenue
- Dynamic filtering across various business dimensions
- Currency conversion to a base currency
- Occupancy and capacity calculations
- Flexible column inclusion/exclusion based on reporting needs

## Key Features

### 1. Dynamic Parameter System
The query uses a sophisticated parameter system with named bind parameters (`:p_*`) that allows for:
- Date range filtering (`p_start_date`, `p_end_date`)
- Multi-dimensional filtering (properties, brands, regions, markets, owners)
- Boolean flags for "select all" functionality
- Array parameters for multi-select filtering
- Column visibility controls

### 2. Currency Conversion
- Automatic currency conversion using exchange rates
- Support for multiple booking currencies
- Conversion to a configurable base currency
- Historical rate lookup based on booking dates

### 3. Multi-Dimensional Filtering
Supports filtering by:
- **Properties**: Individual property selection or all properties
- **Brands**: Hotel brand filtering
- **Regions**: Geographic region filtering
- **Markets**: Market segment filtering
- **Owners**: Property owner filtering
- **Management Types**: Managed vs. Franchised properties
- **Room Categories**: Room type filtering
- **Channels**: Booking channel filtering
- **Loyalty Levels**: Customer loyalty tier filtering
- **Rate Plans**: Pricing plan filtering
- **Intermediaries**: Third-party booking intermediaries
- **Trip Purposes**: Business vs. leisure travel
- **Wholesalers**: Wholesale booking partners
- **Booking Window**: Days between booking and check-in

## Query Structure

### Common Table Expressions (CTEs)

#### 1. `params`
Centralizes all input parameters and provides default values using `COALESCE`.

#### 2. `date_dim`
Generates a date dimension table for the specified date range, including:
- Daily granularity (can be modified for monthly)
- Year, month, and year-month extracts

#### 3. `property_dim`
Normalizes property attributes by joining with dimension tables:
- Properties table
- Brands table
- Regions table
- Markets table
- Owners table
- Management type normalization (M → Managed, F → Franchised)

#### 4. `capacity_agg`
Calculates total available room nights per property:
- Total rooms per property
- Days in the reporting range
- Total room nights (rooms × days)

#### 5. `bookings_fact`
Base fact table containing booking records with date range filtering.

#### 6. `booking_with_rates`
Enriches booking data with:
- Property dimension attributes
- Capacity metrics
- Currency conversion rates using LATERAL join

## Output Columns

### Dimension Columns (Conditional)
- `property_name` - Property name (if `show_property` = true)
- `brand_name` - Brand name (if `show_brand` = true)
- `region_name` - Region name (if `show_region` = true)
- `market_name` - Market name (if `show_market` = true)
- `owner_name` - Owner name (if `show_owner` = true)
- `management_type` - Management type (if `show_mgmt_type` = true)
- `room_category` - Room category name (if `show_room_category` = true)
- `channel_name` - Channel name (if `show_channel` = true)
- `loyalty_level` - Loyalty level (if `show_loyalty` = true)
- `rate_plan_name` - Rate plan name (if `show_rate_plan` = true)
- `intermediary_name` - Intermediary name (if `show_intermediary` = true)
- `trip_purpose` - Trip purpose (if `show_trip_purpose` = true)
- `wholesaler_name` - Wholesaler name (if `show_wholesaler` = true)

### Date Fields
- `booking_date` - Date when booking was made (if `show_booking_date` = true)
- `checkin_date` - Check-in date
- `checkout_date` - Check-out date

### Revenue Fields (Original Currency)
- `room_revenue_original` - Room revenue in booking currency
- `addon_revenue_original` - Additional services revenue
- `package_revenue_original` - Package revenue
- `fee_amount_original` - Fee amounts
- `tax_amount_original` - Tax amounts
- `booking_currency` - Original booking currency

### Revenue Fields (Base Currency)
- `room_revenue_base` - Room revenue converted to base currency
- `addon_revenue_base` - Additional services revenue converted
- `package_revenue_base` - Package revenue converted
- `fee_amount_base` - Fee amounts converted
- `tax_amount_base` - Tax amounts converted
- `total_revenue_base` - Total revenue in base currency

### Capacity and Occupancy Metrics
- `stay_nights` - Number of nights stayed
- `room_nights_sold` - Room nights sold (same as stay_nights for single room bookings)
- `total_rooms` - Total available rooms
- `days_in_range` - Days in reporting period
- `total_room_nights` - Total available room nights
- `occupancy_pct` - Occupancy percentage

## Required Database Tables

The query expects the following tables to exist:
- `properties` - Property master data
- `brands` - Brand dimension
- `regions` - Region dimension
- `markets` - Market dimension
- `owners` - Owner dimension
- `bookings` - Booking fact table
- `currency_rates` - Currency exchange rates
- `room_categories` - Room category dimension
- `channels` - Channel dimension
- `rate_plans` - Rate plan dimension
- `intermediaries` - Intermediary dimension
- `wholesalers` - Wholesaler dimension

## Usage Notes

1. **Parameter Binding**: Adjust parameter binding syntax for your database client (e.g., `$1/$2` for PostgreSQL, `@p` for SQL Server)

2. **Array Parameters**: Uses PostgreSQL array syntax. Adapt for other databases if needed.

3. **Currency Conversion**: Requires a `currency_rates` table with columns:
   - `currency_code`
   - `rate_to_base`
   - `rate_date`
   - `base_currency`

4. **Performance**: Consider adding indexes on frequently filtered columns and date ranges.

5. **Grouping**: The query returns booking-level detail. Uncomment the GROUP BY section for aggregated results.

## Example Usage

```sql
-- Example parameter values
:p_start_date = '2024-01-01'
:p_end_date = '2024-01-31'
:p_property_ids = ARRAY[1, 2, 3]
:p_property_all = false
:p_currency_base = 'USD'
:p_show_property = true
:p_show_brand = true
:p_show_booking_date = true
```

## Performance Considerations

- The query uses LATERAL joins for currency conversion which can be expensive
- Consider materialized views for frequently accessed data
- Index on booking dates and property IDs for better performance
- Monitor query execution plans for large datasets