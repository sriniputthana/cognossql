# Hotel Data Mart SQL Templates

This repository contains comprehensive SQL templates for hotel data mart implementations, designed for multi-dimensional hotel analytics and reporting.

## Files Overview

### 📊 [atr](atr) - Account Tracking Report
A comprehensive PostgreSQL query for hotel revenue management and analytics with multi-dimensional filtering capabilities.

**Key Features:**
- Dynamic parameter system with named bind parameters
- Multi-dimensional filtering (properties, brands, regions, markets, owners)
- Currency conversion with historical rate lookup
- Occupancy and capacity calculations
- Flexible column inclusion/exclusion

**Use Cases:**
- Revenue analysis and reporting
- Property performance tracking
- Multi-property portfolio analysis
- Currency-normalized reporting

### 📈 [dat3](dat3) - DAT3_Details.sql
A dynamic hotel data mart report template with extensive filtering and dynamic column inclusion capabilities.

**Key Features:**
- Dynamic column inclusion based on boolean parameters
- Comprehensive filtering across all hotel business dimensions
- Currency conversion and normalization
- Occupancy and capacity analytics
- Revenue tracking and analysis

**Use Cases:**
- Executive dashboards
- Operational reporting
- Financial analysis
- Market performance analysis

## Quick Start

### Prerequisites
- PostgreSQL database (primary target)
- Hotel data mart schema with required tables
- Currency exchange rate data

### Required Database Tables
Both queries expect the following core tables:
- `properties` - Property master data
- `brands` - Brand dimension
- `regions` - Region dimension
- `markets` - Market dimension
- `owners` - Owner dimension
- `bookings` - Booking fact table
- `currency_rates` - Currency exchange rates

### Basic Usage

1. **Set up your database schema** with the required tables
2. **Load currency exchange rate data** into the `currency_rates` table
3. **Configure parameters** for your specific reporting needs
4. **Execute the queries** with appropriate parameter values

### Example Parameter Configuration

```sql
-- Basic revenue report parameters
:p_start_date = '2024-01-01'
:p_end_date = '2024-01-31'
:p_property_all = true
:p_currency_base = 'USD'
:p_show_property = true
:p_show_brand = true
:p_show_booking_date = true
```

## Documentation

- **[ATR Documentation](atr.md)** - Detailed documentation for the Account Tracking Report
- **[DAT3 Documentation](dat3.md)** - Comprehensive documentation for the DAT3_Details.sql template

## Key Differences

| Feature | ATR | DAT3_Details |
|---------|-----|--------------|
| **Primary Focus** | Account tracking and revenue analysis | Dynamic data mart reporting |
| **Column Control** | Basic conditional columns | Extensive dynamic column inclusion |
| **Filtering** | Multi-dimensional with "all" options | Comprehensive filtering system |
| **Currency Support** | Full currency conversion | Full currency conversion |
| **Use Case** | Revenue management | Executive reporting |
| **Complexity** | Intermediate | Advanced |

## Database Compatibility

### PostgreSQL (Primary Target)
- Full feature support
- Array parameter support
- LATERAL join support
- Advanced date functions

### Other Databases
Both queries can be adapted for:
- **SQL Server**: Requires syntax adjustments for type casting, array handling, and LATERAL joins
- **Oracle**: Requires hierarchical queries and different array handling
- **MySQL**: Limited array support, requires workarounds

## Performance Considerations

### Recommended Indexes
```sql
-- Core indexes for optimal performance
CREATE INDEX idx_bookings_dates ON bookings (checkin_date, checkout_date);
CREATE INDEX idx_bookings_property ON bookings (property_id);
CREATE INDEX idx_currency_rates_lookup ON currency_rates (currency_code, rate_date DESC);
CREATE INDEX idx_properties_brand ON properties (brand_id);
```

### Optimization Tips
1. Use appropriate date range filtering
2. Consider materialized views for frequently accessed data
3. Monitor query execution plans
4. Use connection pooling for high-frequency queries
5. Consider partitioning large fact tables by date

## Schema Requirements

### Core Dimension Tables
- **Properties**: Property master data with brand, region, market, and owner relationships
- **Brands**: Hotel brand information
- **Regions**: Geographic region definitions
- **Markets**: Market segment classifications
- **Owners**: Property owner information

### Fact Tables
- **Bookings**: Core booking data with revenue, dates, and dimensional keys
- **Currency Rates**: Exchange rate data for currency conversion

### Supporting Dimensions
- **Room Categories**: Room type classifications
- **Channels**: Booking channel definitions
- **Rate Plans**: Pricing plan information
- **Intermediaries**: Third-party booking intermediaries
- **Wholesalers**: Wholesale booking partners

## Common Use Cases

### 1. Revenue Analysis
- Track revenue across properties, brands, and regions
- Analyze revenue by booking channel and customer segment
- Monitor currency-normalized performance

### 2. Occupancy Analysis
- Calculate occupancy rates and capacity utilization
- Analyze booking patterns and trends
- Track performance across different market segments

### 3. Operational Reporting
- Generate executive dashboards
- Create operational reports for different stakeholders
- Monitor key performance indicators (KPIs)

### 4. Financial Analysis
- Currency-normalized financial reporting
- Revenue breakdown by various dimensions
- Cost and profitability analysis

## Troubleshooting

### Common Issues
1. **Currency Conversion Errors**: Verify currency_rates table completeness
2. **Performance Issues**: Check indexes and query optimization
3. **Parameter Binding Errors**: Ensure proper parameter syntax
4. **Array Parameter Issues**: Verify array parameter format

### Getting Help
1. Check the detailed documentation for each file
2. Verify your database schema matches requirements
3. Test with small date ranges first
4. Use EXPLAIN ANALYZE for performance debugging

## Contributing

When contributing to these SQL templates:
1. Maintain backward compatibility with existing parameters
2. Document any new features or changes
3. Test with various parameter combinations
4. Update documentation as needed
5. Consider performance implications of changes

## License

These SQL templates are provided as-is for hotel data mart implementations. Please ensure compliance with your organization's data usage policies and database licensing requirements.

## Support

For questions or issues:
1. Review the detailed documentation for each file
2. Check database schema requirements
3. Verify parameter configuration
4. Test with sample data first

---

**Note**: These templates are designed for PostgreSQL but can be adapted for other database systems with appropriate syntax modifications.