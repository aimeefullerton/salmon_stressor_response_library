| Column         | Description                                                                    | Type    | Rules                                                                      |
| -------------- | ------------------------------------------------------------------------------ | ------- | -------------------------------------------------------------------------- |
| curve.id       | Unique curve identifier; one id per curve                                      | string  | REQUIRED; Required for single-curve files (can use a single value like c1) |
| stressor.label | Name of the stressor for the entire file                                       | string  | REQUIRED; Must have exactly 1 unique non-NA value across the entire file   |
| stressor.x     | Numeric value of the stressor (x-axis)                                         | numeric | REQUIRED; X-values only; Must be numeric                                   |
| units.x        | Units for stressor.x                                                           | string  | REQUIRED; Must have exactly 1 unique non-NA value across the entire file   |
| response.label | Name of the response variable (y-axis)                                         | string  | REQUIRED; Must have exactly 1 unique non-NA value across the entire file   |
| response.y     | Numeric value of the biological response (y-axis)                              | numeric | REQUIRED; Y-values only; Must be numeric                                   |
| units.y        | Units for response.y                                                           | string  | REQUIRED; Must have exactly 1 unique non-NA value across the entire file   |
| stressor.value | Optional curve-level descriptor (e.g., temperature 14, "low", replicate label) | any     | OPTIONAL; Can be any type, preferably a string or number                   |
| lower.limit    | Optional lower confidence/uncertainty bound for response.y                     | numeric | OPTIONAL; NA allowed                                                       |
| upper.limit    | Optional upper confidence/uncertainty bound for response.y                     | numeric | OPTIONAL; NA allowed                                                       |
| sd             | Optional standard deviation for response.y                                     | numeric | OPTIONAL; NA allowed                                                       |

### Examples of valid CSV files:

_Note: the minimum number of data rows **per curve** for a valid csv file is **4**._

#### Valid CSV File with No Optional Columns and a Single Curve

```csv
curve.id,stressor.label,stressor.x,units.x,response.label,response.y,units.y
c1,temperature,0.5,degC,survival,92,percent
c1,temperature,1.0,degC,survival,85,percent
c1,temperature,1.5,degC,survival,70,percent
c1,temperature,2.0,degC,survival,66,percent
```

#### Valid CSV File with All Optional Columns and Multiple Curves

```csv
curve.id,stressor.label,stressor.x,units.x,response.label,response.y,units.y,stressor.value,lower.limit,upper.limit,sd
low_temp,water_temperature,5,degC,embryo_survival,0.95,proportion,5C,0.89,1.00,0.03
low_temp,water_temperature,10,degC,embryo_survival,0.92,proportion,5C,0.84,1.00,0.04
low_temp,water_temperature,15,degC,embryo_survival,0.88,proportion,5C,0.78,0.98,0.05
low_temp,water_temperature,20,degC,embryo_survival,0.86,proportion,5C,0.74,0.98,0.06
med_temp,water_temperature,5,degC,embryo_survival,0.85,proportion,10C,0.77,0.93,0.04
med_temp,water_temperature,10,degC,embryo_survival,0.75,proportion,10C,0.63,0.87,0.06
med_temp,water_temperature,15,degC,embryo_survival,0.60,proportion,10C,0.44,0.76,0.08
med_temp,water_temperature,20,degC,embryo_survival,0.55,proportion,10C,0.40,0.71,0.10
high_temp,water_temperature,5,degC,embryo_survival,0.70,proportion,15C,0.56,0.84,0.07
high_temp,water_temperature,10,degC,embryo_survival,0.50,proportion,15C,0.32,0.68,0.09
high_temp,water_temperature,15,degC,embryo_survival,0.30,proportion,15C,0.10,0.50,0.10
high_temp,water_temperature,20,degC,embryo_survival,0.10,proportion,15C,0.02,0.22,0.12
```
