# DAT3_Details.sql - Dynamic Hotel Data Mart Report Template

## Overview
DAT3_Details.sql is a comprehensive PostgreSQL-based dynamic hotel data mart report template designed for multi-dimensional hotel analytics and reporting. It provides a flexible framework for generating detailed hotel booking and revenue reports with extensive filtering and dynamic column inclusion capabilities.

## Purpose
This SQL template serves as a foundation for hotel data mart implementations, enabling:
- Multi-dimensional hotel data analysis
- Dynamic report generation with configurable columns
- Comprehensive filtering across all hotel business dimensions
- Currency conversion and normalization
- Occupancy and capacity analytics
- Revenue tracking and analysis

## Key Features

### 1. Dynamic Column Inclusion
The query uses conditional column inclusion based on boolean parameters:
- `p_show_property` - Include property information
- `p_show_brand` - Include brand information
- `p_show_region` - Include region information
- `p_show_market` - Include market information
- `p_show_owner` - Include owner information
- `p_show_mgmt_type` - Include management type
- `p_show_room_category` - Include room category
- `p_show_channel` - Include booking channel
- `p_show_loyalty` - Include loyalty level
- `p_show_rate_plan` - Include rate plan
- `p_show_intermediary` - Include intermediary
- `p_show_trip_purpose` - Include trip purpose
- `p_show_wholesaler` - Include wholesaler
- `p_show_booking_date` - Include booking date

### 2. Comprehensive Filtering System
Supports filtering across multiple dimensions:

#### Geographic Filters
- **Properties**: Individual property selection or all properties
- **Brands**: Hotel brand filtering with "all" option
- **Regions**: Geographic region filtering
- **Markets**: Market segment filtering

#### Business Filters
- **Owners**: Property owner filtering
- **Management Types**: Managed vs. Franchised properties
- **Room Categories**: Room type filtering
- **Channels**: Booking channel filtering
- **Loyalty Levels**: Customer loyalty tier filtering
- **Rate Plans**: Pricing plan filtering
- **Intermediaries**: Third-party booking intermediaries
- **Trip Purposes**: Business vs. leisure travel
- **Wholesalers**: Wholesale booking partners

#### Temporal Filters
- **Date Range**: Start and end date filtering
- **Booking Window**: Days between booking and check-in dates

### 3. Currency Conversion System
- Multi-currency support with automatic conversion
- Historical exchange rate lookup
- Configurable base currency
- Real-time currency conversion using LATERAL joins

## Query Architecture

### Common Table Expressions (CTEs)

#### 1. `params`
Central parameter management CTE that:
- Defines all input parameters with proper data types
- Provides default values using `COALESCE`
- Manages both filter parameters and column visibility flags

#### 2. `date_dim`
Date dimension generator that:
- Creates daily granularity for the specified date range
- Extracts year, month, and year-month components
- Can be modified for different time granularities

#### 3. `property_dim`
Property dimension normalization that:
- Joins properties with all related dimension tables
- Normalizes management type codes (M → Managed, F → Franchised)
- Provides comprehensive property attributes

#### 4. `capacity_agg`
Capacity calculation CTE that:
- Calculates total available room nights per property
- Computes days in the reporting range
- Provides capacity metrics for occupancy calculations

#### 5. `bookings_fact`
Base booking fact table that:
- Filters bookings intersecting the date range
- Provides the foundation for all subsequent joins

#### 6. `booking_with_rates`
Enhanced booking data that:
- Joins booking facts with property dimensions
- Adds capacity metrics
- Performs currency conversion using LATERAL joins

## Output Schema

### Dimension Columns (Conditional)
All dimension columns are conditionally included based on corresponding `p_show_*` parameters:

| Column | Description | Condition |
|--------|-------------|-----------|
| `property_name` | Property name | `p_show_property = true` |
| `brand_name` | Brand name | `p_show_brand = true` |
| `region_name` | Region name | `p_show_region = true` |
| `market_name` | Market name | `p_show_market = true` |
| `owner_name` | Owner name | `p_show_owner = true` |
| `management_type` | Management type | `p_show_mgmt_type = true` |
| `room_category` | Room category | `p_show_room_category = true` |
| `channel_name` | Channel name | `p_show_channel = true` |
| `loyalty_level` | Loyalty level | `p_show_loyalty = true` |
| `rate_plan_name` | Rate plan name | `p_show_rate_plan = true` |
| `intermediary_name` | Intermediary name | `p_show_intermediary = true` |
| `trip_purpose` | Trip purpose | `p_show_trip_purpose = true` |
| `wholesaler_name` | Wholesaler name | `p_show_wholesaler = true` |

### Date Fields
- `booking_date` - Date when booking was made (conditional)
- `checkin_date` - Check-in date (always included)
- `checkout_date` - Check-out date (always included)

### Revenue Metrics

#### Original Currency
- `room_revenue_original` - Room revenue in booking currency
- `addon_revenue_original` - Additional services revenue
- `package_revenue_original` - Package revenue
- `fee_amount_original` - Fee amounts
- `tax_amount_original` - Tax amounts
- `booking_currency` - Original booking currency code

#### Base Currency (Converted)
- `room_revenue_base` - Room revenue in base currency
- `addon_revenue_base` - Additional services revenue in base currency
- `package_revenue_base` - Package revenue in base currency
- `fee_amount_base` - Fee amounts in base currency
- `tax_amount_base` - Tax amounts in base currency
- `total_revenue_base` - Total revenue in base currency

### Capacity and Occupancy Metrics
- `stay_nights` - Number of nights stayed
- `room_nights_sold` - Room nights sold
- `total_rooms` - Total available rooms
- `days_in_range` - Days in reporting period
- `total_room_nights` - Total available room nights
- `occupancy_pct` - Occupancy percentage

## Required Database Schema

### Core Tables
- `properties` - Property master data
- `brands` - Brand dimension
- `regions` - Region dimension
- `markets` - Market dimension
- `owners` - Owner dimension
- `bookings` - Booking fact table

### Supporting Tables
- `currency_rates` - Currency exchange rates
- `room_categories` - Room category dimension
- `channels` - Channel dimension
- `rate_plans` - Rate plan dimension
- `intermediaries` - Intermediary dimension
- `wholesalers` - Wholesaler dimension

### Currency Rates Table Structure
```sql
CREATE TABLE currency_rates (
    currency_code VARCHAR(3),
    rate_to_base DECIMAL(10,6),
    rate_date DATE,
    base_currency VARCHAR(3)
);
```

## Parameter Reference

### Date Parameters
- `:p_start_date` (DATE) - Report start date
- `:p_end_date` (DATE) - Report end date

### Filter Parameters
- `:p_property_ids` (INT[]) - Array of property IDs
- `:p_property_all` (BOOLEAN) - Include all properties
- `:p_brand_ids` (INT[]) - Array of brand IDs
- `:p_brand_all` (BOOLEAN) - Include all brands
- `:p_region_ids` (INT[]) - Array of region IDs
- `:p_region_all` (BOOLEAN) - Include all regions
- `:p_market_ids` (INT[]) - Array of market IDs
- `:p_market_all` (BOOLEAN) - Include all markets
- `:p_owner_ids` (INT[]) - Array of owner IDs
- `:p_owner_all` (BOOLEAN) - Include all owners
- `:p_management_types` (TEXT[]) - Array of management types
- `:p_management_all` (BOOLEAN) - Include all management types
- `:p_room_category_ids` (INT[]) - Array of room category IDs
- `:p_channel_ids` (INT[]) - Array of channel IDs
- `:p_loyalty_levels` (TEXT[]) - Array of loyalty levels
- `:p_booking_window_from` (INT) - Minimum booking window (days)
- `:p_booking_window_to` (INT) - Maximum booking window (days)
- `:p_rate_plan_ids` (INT[]) - Array of rate plan IDs
- `:p_intermediary_ids` (INT[]) - Array of intermediary IDs
- `:p_trip_purposes` (TEXT[]) - Array of trip purposes
- `:p_wholesaler_ids` (INT[]) - Array of wholesaler IDs
- `:p_currency_base` (TEXT) - Base currency code (e.g., 'USD')

### Column Visibility Parameters
- `:p_show_property` (BOOLEAN) - Show property column
- `:p_show_brand` (BOOLEAN) - Show brand column
- `:p_show_region` (BOOLEAN) - Show region column
- `:p_show_market` (BOOLEAN) - Show market column
- `:p_show_owner` (BOOLEAN) - Show owner column
- `:p_show_mgmt_type` (BOOLEAN) - Show management type column
- `:p_show_room_category` (BOOLEAN) - Show room category column
- `:p_show_channel` (BOOLEAN) - Show channel column
- `:p_show_loyalty` (BOOLEAN) - Show loyalty column
- `:p_show_rate_plan` (BOOLEAN) - Show rate plan column
- `:p_show_intermediary` (BOOLEAN) - Show intermediary column
- `:p_show_trip_purpose` (BOOLEAN) - Show trip purpose column
- `:p_show_wholesaler` (BOOLEAN) - Show wholesaler column
- `:p_show_booking_date` (BOOLEAN) - Show booking date column

## Usage Examples

### Basic Revenue Report
```sql
-- Parameters for basic revenue report
:p_start_date = '2024-01-01'
:p_end_date = '2024-01-31'
:p_property_all = true
:p_currency_base = 'USD'
:p_show_property = true
:p_show_brand = true
:p_show_booking_date = true
```

### Brand Performance Analysis
```sql
-- Parameters for brand performance analysis
:p_start_date = '2024-01-01'
:p_end_date = '2024-12-31'
:p_brand_ids = ARRAY[1, 2, 3]
:p_brand_all = false
:p_currency_base = 'USD'
:p_show_brand = true
:p_show_region = true
:p_show_market = true
```

### Channel Analysis
```sql
-- Parameters for channel analysis
:p_start_date = '2024-01-01'
:p_end_date = '2024-01-31'
:p_property_all = true
:p_channel_ids = ARRAY[1, 2, 3, 4]
:p_currency_base = 'USD'
:p_show_channel = true
:p_show_loyalty = true
:p_show_rate_plan = true
```

## Performance Optimization

### Recommended Indexes
```sql
-- Booking table indexes
CREATE INDEX idx_bookings_dates ON bookings (checkin_date, checkout_date);
CREATE INDEX idx_bookings_property ON bookings (property_id);
CREATE INDEX idx_bookings_booking_date ON bookings (booking_date);

-- Currency rates indexes
CREATE INDEX idx_currency_rates_lookup ON currency_rates (currency_code, rate_date DESC);

-- Property dimension indexes
CREATE INDEX idx_properties_brand ON properties (brand_id);
CREATE INDEX idx_properties_region ON properties (region_id);
CREATE INDEX idx_properties_market ON properties (market_id);
CREATE INDEX idx_properties_owner ON properties (owner_id);
```

### Query Optimization Tips
1. Use appropriate date range filtering to limit data volume
2. Consider materialized views for frequently accessed data
3. Monitor query execution plans for large datasets
4. Use connection pooling for high-frequency queries
5. Consider partitioning large fact tables by date

## Database Compatibility

### PostgreSQL (Primary)
- Full feature support
- Array parameter support
- LATERAL join support
- Advanced date functions

### SQL Server (Adaptation Required)
- Replace `::` type casting with `CAST()` function
- Replace `GENERATE_SERIES` with recursive CTE
- Replace `ANY()` array operator with `IN` clause
- Replace `LATERAL` joins with subqueries

### Oracle (Adaptation Required)
- Replace `::` type casting with `CAST()` function
- Replace `GENERATE_SERIES` with hierarchical query
- Replace `ANY()` array operator with `IN` clause
- Replace `LATERAL` joins with subqueries
- Adjust date arithmetic syntax

## Maintenance and Updates

### Regular Maintenance Tasks
1. Update currency rates table with latest exchange rates
2. Monitor query performance and optimize as needed
3. Update dimension tables as business structure changes
4. Review and update parameter validation logic
5. Test with different parameter combinations

### Version Control
- Track changes to parameter definitions
- Document schema changes
- Maintain test cases for different scenarios
- Version control query templates

## Troubleshooting

### Common Issues
1. **Currency Conversion Errors**: Verify currency_rates table has data for all booking currencies
2. **Performance Issues**: Check indexes and consider query optimization
3. **Parameter Binding Errors**: Ensure proper parameter syntax for your database client
4. **Array Parameter Issues**: Verify array parameter format matches database expectations

### Debugging Tips
1. Test with small date ranges first
2. Use EXPLAIN ANALYZE to identify performance bottlenecks
3. Validate parameter values before execution
4. Check for missing dimension data
5. Verify currency rate data completeness