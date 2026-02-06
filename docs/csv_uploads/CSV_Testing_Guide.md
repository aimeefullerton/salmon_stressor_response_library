# Comprehensive CSV Test Suite Documentation

## All Test Cases with Expected Results

---

## Test Suite Overview

This test suite contains **14 carefully designed CSV files** that validate all aspects of the CSV validation system:

- **Valid Files (4)**: Files that should pass validation
- **Invalid Files (8)**: Files that should fail validation with specific error messages
- **Security Tests (2)**: Files testing security features (formula injection, SQL injection)

---

## VALID TEST CASES (Should Pass)

### Test 01: Valid Single Curve Minimal ✓

**File:** `valid_single_curve_minimal.csv`

**Description:** Basic valid file with only required columns and a single curve.

**Content:**

```csv
curve.id,stressor.x,response.y,stressor.label,response.label,units.x,units.y
c1,0.5,92,temperature,survival,degC,percent
c1,1.0,85,temperature,survival,degC,percent
c1,1.5,70,temperature,survival,degC,percent
c1,2.0,66,temperature,survival,degC,percent
```

**Why it passes:**

- ✓ All 7 required columns present
- ✓ No optional columns (valid to omit)
- ✓ Single curve "c1" with 4 valid data points
- ✓ All label/unit columns have single unique values
- ✓ All numeric columns contain valid numbers

**Expected Output:**

- Valid: TRUE
- Rows: 4
- Curves: 1
- Stressor: temperature (degC)
- Response: survival (percent)

---

### Test 02: Valid Multi-Curve with Stressor Value ✓

**File:** `valid_multi_curve_with_stressor_value.csv`

**Description:** Multiple curves in one file with optional stressor.value differing per curve.

**Content:**

```csv
curve.id,stressor.x,response.y,sd,lower.limit,upper.limit,stressor.label,stressor.value,response.label,units.x,units.y
temp.14,0.5,92,NA,NA,NA,temperature,14,survival,degC,percent
temp.14,0.7,90,NA,NA,NA,temperature,14,survival,degC,percent
temp.14,0.9,87,NA,NA,NA,temperature,14,survival,degC,percent
temp.14,1.0,85,NA,NA,NA,temperature,14,survival,degC,percent
temp.18,0.5,75,NA,NA,NA,temperature,18,survival,degC,percent
temp.18,0.6,72,NA,NA,NA,temperature,18,survival,degC,percent
temp.18,0.8,68,NA,NA,NA,temperature,18,survival,degC,percent
temp.18,1.0,60,NA,NA,NA,temperature,18,survival,degC,percent
```

**Why it passes:**

- ✓ Multiple curves supported (temp.14, temp.18)
- ✓ Each curve has ≥4 valid data points
- ✓ stressor.value can vary between curves (14 vs 18)
- ✓ Optional columns (sd, lower.limit, upper.limit) can be NA
- ✓ stressor.label, response.label, units consistent across all rows

**Expected Output:**

- Valid: TRUE
- Rows: 8
- Curves: 2
- Stressor: temperature (degC)
- Response: survival (percent)

---

### Test 03: Valid Uncertainty Populated ✓

**File:** `valid_uncertainty_populated.csv`

**Description:** Single curve with all optional uncertainty columns populated with real values.

**Content:**

```csv
curve.id,stressor.x,response.y,sd,lower.limit,upper.limit,stressor.label,stressor.value,response.label,units.x,units.y
c1,10,0.90,0.05,0.80,1.00,sediment,10,emergence.probability,percent,probability
c1,20,0.70,0.06,0.58,0.82,sediment,10,emergence.probability,percent,probability
c1,30,0.40,0.08,0.24,0.56,sediment,10,emergence.probability,percent,probability
c1,40,0.20,0.10,0.04,0.24,sediment,10,emergence.probability,percent,probability
```

**Why it passes:**

- ✓ All optional columns populated with numeric values
- ✓ limit logic validated: lower.limit ≤ upper.limit in all rows
- ✓ 4 valid data points for curve "c1"
- ✓ Response label can have dots (emergence.probability)

**Expected Output:**

- Valid: TRUE
- Rows: 4
- Curves: 1
- Stressor: sediment (percent)
- Response: emergence.probability (probability)

---

### Test 04: Valid Complex Multi-Curve ✓

**File:** `valid_complex_multi_curve.csv`

**Description:** Complex scenario with 3 curves, each with 3 points, all optional columns populated.

**Content:**

```csv
curve.id,stressor.x,response.y,sd,lower.limit,upper.limit,stressor.label,stressor.value,response.label,units.x,units.y
low_temp,5,0.95,0.03,0.89,1.00,water_temperature,5C,embryo_survival,degC,proportion
low_temp,10,0.92,0.04,0.84,1.00,water_temperature,5C,embryo_survival,degC,proportion
low_temp,15,0.88,0.05,0.78,0.98,water_temperature,5C,embryo_survival,degC,proportion
low_temp,20,0.86,0.06,0.74,0.98,water_temperature,5C,embryo_survival,degC,proportion
med_temp,5,0.85,0.04,0.77,0.93,water_temperature,10C,embryo_survival,degC,proportion
med_temp,10,0.75,0.06,0.63,0.87,water_temperature,10C,embryo_survival,degC,proportion
med_temp,15,0.60,0.08,0.44,0.76,water_temperature,10C,embryo_survival,degC,proportion
med_temp,20,0.55,0.10,0.40,0.71,water_temperature,10C,embryo_survival,degC,proportion
high_temp,5,0.70,0.07,0.56,0.84,water_temperature,15C,embryo_survival,degC,proportion
high_temp,10,0.50,0.09,0.32,0.68,water_temperature,15C,embryo_survival,degC,proportion
high_temp,15,0.30,0.10,0.10,0.50,water_temperature,15C,embryo_survival,degC,proportion
high_temp,20,0.10,0.12,0.02,0.22,water_temperature,15C,embryo_survival,degC,proportion
```

**Why it passes:**

- ✓ 3 separate curves (low_temp, med_temp, high_temp)
- ✓ Each curve has 4 valid data points
- ✓ stressor.value differs per curve (5C, 10C, 15C, 20C)
- ✓ All uncertainty columns populated correctly
- ✓ Complex naming (water_temperature, embryo_survival with underscores)

**Expected Output:**

- Valid: TRUE
- Rows: 12
- Curves: 3
- Stressor: water_temperature (degC)
- Response: embryo_survival (proportion)

---

## INVALID TEST CASES (Should Fail)

### Test 05: Invalid Multiple Stressor Labels ✗

**File:** `invalid_multiple_stressor_labels.csv`

**Description:** File with different stressor.label values across rows.

**Content:**

```csv
curve.id,stressor.x,response.y,stressor.label,response.label,units.x,units.y
c1,0.5,92,temperature,survival,degC,percent
c1,1.0,85,flow,survival,degC,percent
```

**Why it fails:**

- ✗ stressor.label has 2 unique values: "temperature" and "flow"
- ✗ Violates rule: label columns must have exactly 1 unique value

**Expected Error:**

```
Column 'stressor.label' has multiple unique values (temperature, flow) but must have exactly 1 unique value across the entire file

How to fix: The stressor.label, response.label, units.x, and units.y columns must have the same value in every row
```

---

### Test 06: Invalid Curve Too Few Points ✗

**File:** `invalid_curve_too_few_points.csv`

**Description:** Curve with only 1 valid data point (has NA values in other rows).

**Content:**

```csv
curve.id,stressor.x,response.y,stressor.label,response.label,units.x,units.y
c1,0.5,92,temperature,survival,degC,percent
c1,NA,85,temperature,survival,degC,percent
c1,1.5,NA,temperature,survival,degC,percent
```

**Why it fails:**

- ✗ Row 1: valid (stressor.x=0.5, response.y=92)
- ✗ Row 2: invalid (stressor.x=NA)
- ✗ Row 3: invalid (response.y=NA)
- ✗ Only 1 valid point, minimum is 4

**Expected Error:**

```
Curve 'c1' has only 1 valid data point(s) with non-NA stressor.x and response.y values. Minimum required: 4

How to fix: Each curve must have at least 4 rows where BOTH stressor.x and response.y are non-NA numbers
```

---

### Test 07: Invalid Missing units.x Column ✗

**File:** `invalid_missing_units_x_column.csv`

**Description:** Missing a required column (units.x).

**Content:**

```csv
curve.id,stressor.x,response.y,stressor.label,response.label,units.y
c1,10,0.9,temperature,survival,percent
c1,20,0.8,temperature,survival,percent
c1,30,0.7,temperature,survival,percent
c1,30,0.6,temperature,survival,percent
```

**Why it fails:**

- ✗ Missing required column: units.x
- ✗ Only 6 columns present, need 7 required

**Expected Error:**

```
Missing required column: 'units.x'

How to fix: Ensure your CSV has these exact column names (case-insensitive):
• curve.id
• stressor.x
• response.y
• stressor.label
• response.label
• units.x
• units.y
```

---

### Test 08: Invalid Non-Numeric stressor.x ✗

**File:** `invalid_non_numeric_stressor_x.csv`

**Description:** Text value in numeric column.

**Content:**

```csv
curve.id,stressor.x,response.y,stressor.label,response.label,units.x,units.y
c1,10,0.9,temperature,survival,degC,percent
c1,twenty,0.8,temperature,survival,degC,percent
c1,30,0.7,temperature,survival,degC,percent
c1,40,0.6,temperature,survival,degC,percent
```

**Why it fails:**

- ✗ stressor.x contains "twenty" which is not numeric
- ✗ Row 2 has invalid data type

**Expected Error:**

```
Column 'stressor.x' contains non-numeric values: twenty (in rows 2)

How to fix: Ensure stressor.x and response.y columns contain only numbers (NA is allowed)
```

---

### Test 09: Invalid Multiple units.x Values ✗

**File:** `invalid_multiple_units_x.csv`

**Description:** Different unit values across rows.

**Content:**

```csv
curve.id,stressor.x,response.y,stressor.label,response.label,units.x,units.y
c1,10,0.9,temperature,survival,degC,percent
c1,20,0.8,temperature,survival,degF,percent
c1,30,0.7,temperature,survival,degC,percent
c1,40,0.6,temperature,survival,degC,percent
```

**Why it fails:**

- ✗ units.x has 2 unique values: "degC" and "degF"
- ✗ Violates single unique value rule

**Expected Error:**

```
Column 'units.x' has multiple unique values (degC, degF) but must have exactly 1 unique value across the entire file

How to fix: The stressor.label, response.label, units.x, and units.y columns must have the same value in every row
```

---

### Test 10: Invalid Empty curve.id ✗

**File:** `invalid_empty_curve_id.csv`

**Description:** Row with empty/missing curve.id value.

**Content:**

```csv
curve.id,stressor.x,response.y,stressor.label,response.label,units.x,units.y
c1,10,0.9,temperature,survival,degC,percent
,20,0.8,temperature,survival,degC,percent
c1,30,0.7,temperature,survival,degC,percent
c1,40,0.6,temperature,survival,degC,percent
```

**Why it fails:**

- ✗ Row 2 has empty curve.id
- ✗ curve.id is required for all rows

**Expected Error:**

```
Column 'curve.id' has 1 empty values (all rows must have a curve ID)
```

---

### Test 11: Invalid Limit Logic ✗

**File:** `invalid_limit_logic.csv`

**Description:** Lower limit exceeds upper limit.

**Content:**

```csv
curve.id,stressor.x,response.y,sd,lower.limit,upper.limit,stressor.label,response.label,units.x,units.y
c1,10,0.9,0.05,0.95,0.85,temperature,survival,degC,percent
c1,20,0.8,0.05,0.75,0.85,temperature,survival,degC,percent
c1,30,0.7,0.05,0.65,0.75,temperature,survival,degC,percent
c1,40,0.6,0.05,0.65,0.75,temperature,survival,degC,percent
```

**Why it fails:**

- ✗ Row 1: lower.limit (0.95) > upper.limit (0.85)
- ✗ Violates logic: lower must be ≤ upper

**Expected Error:**

```
Lower limit exceeds upper limit in rows: 1
```

---

### Test 12: Invalid Empty File ✗

**File:** `invalid_empty_file.csv`

**Description:** File with headers but no data rows.

**Content:**

```csv
curve.id,stressor.x,response.y,stressor.label,response.label,units.x,units.y
```

**Why it fails:**

- ✗ No data rows present
- ✗ 0 rows of data

**Expected Error:**

```
CSV file is empty. Please include at least one data row.
```

---

## SECURITY TEST CASES

### Test 13: Security - Formula Injection 🛡️

**File:** `security_formula_injection.csv`

**Description:** Cell with formula prefix (=) that should be neutralized.

**Content:**

```csv
curve.id,stressor.x,response.y,stressor.label,response.label,units.x,units.y
c1,10,0.9,=2+2,survival,degC,percent
c1,20,0.8,temperature,survival,degC,percent
c1,30,0.7,temperature,survival,degC,percent
c1,40,0.6,temperature,survival,degC,percent
```

**Why it should fail:**

- ✗ Multiple unique values in stressor.label: "=2+2" and "temperature"
- ✗ But the "=2+2" will be sanitized to "'=2+2" (with leading quote)

**Expected Behavior:**

- Valid: FALSE (fails due to multiple labels)
- Security: Formula detected and neutralized
- Formula "=2+2" becomes "'=2+2" in sanitized data

**Note:** If this had the same label in all rows, it would PASS with the formula neutralized.

---

### Test 14: Security - SQL Injection 🛡️

**File:** `security_sql_injection.csv`

**Description:** SQL injection attempt in optional stressor.value column.

**Content:**

```csv
curve.id,stressor.x,response.y,stressor.label,response.label,units.x,units.y,stressor.value
c1,10,0.9,temperature,survival,degC,percent,'; DROP TABLE users; --
c1,20,0.8,temperature,survival,degC,percent,normal
c1,30,0.7,temperature,survival,degC,percent,normal
c1,40,0.6,temperature,survival,degC,percent,normal
```

**Why it should pass (with warning):**

- ✓ All required columns valid
- ✓ stressor.value is optional and can contain any text
- 🛡️ SQL pattern detected in stressor.value
- 🛡️ Safe due to parameterized queries

**Expected Behavior:**

- Valid: TRUE
- Security Warning: "Column 'stressor.value' contains suspicious patterns in rows 1"
- Data stored safely via parameterized query (SQL injection cannot execute)

---

## Test Suite Summary Table

| #   | Filename                                    | Type     | Expected    | Key Test            |
| --- | ------------------------------------------- | -------- | ----------- | ------------------- |
| 01  | `invalid_curve_too_few_points.csv`          | Invalid  | FAIL        | Minimum points      |
| 02  | `invalid_empty_curve_id.csv`                | Invalid  | FAIL        | Required field      |
| 03  | `invalid_empty_file.csv`                    | Invalid  | FAIL        | Empty file          |
| 04  | `invalid_limit_logic.csv`                   | Invalid  | FAIL        | Limit logic         |
| 05  | `invalid_missing_units_x_column.csv`        | Invalid  | FAIL        | Missing column      |
| 06  | `invalid_multiple_stressor_labels.csv`      | Invalid  | FAIL        | Single unique value |
| 07  | `invalid_multiple_units_x.csv`              | Invalid  | FAIL        | Unit consistency    |
| 08  | `invalid_non_numeric_stressor_x.csv`        | Invalid  | FAIL        | Data type           |
| 09  | `security_formula_injection.csv`            | Security | FAIL\*      | Formula injection   |
| 10  | `security_sql_injection.csv`                | Security | PASS + WARN | SQL injection       |
| 11  | `valid_complex_multi_curve.csv`             | Valid    | PASS        | Complex scenario    |
| 12  | `valid_multi_curve_with_stressor_value.csv` | Valid    | PASS        | Multi-curve support |
| 13  | `valid_single_curve_minimal.csv`            | Valid    | PASS        | Basic structure     |
| 14  | `valid_uncertainty_populated.csv`           | Valid    | PASS        | Optional columns    |

**Note:** Test 09 fails validation due to multiple labels, but demonstrates formula sanitization.

---

## Running the Test Suite

### Manual Testing

1. Upload each file
2. Verify the validation result matches expected outcome
3. Check error messages are clear and actionable
4. For valid files, verify data is stored correctly in database

### Automated Testing

```r
source("csv_validation.R")

# Test all files
test_files <- list.files("/data/test_csv_files", full.names = TRUE, pattern = "\\.csv$")

for (file in test_files) {
  file_input <- list(
    datapath = file,
    name = basename(file),
    type = "text/csv",
    size = file.info(file)$size
  )

  result <- validate_csv_upload(file_input)
  cat(sprintf("%s: %s\n", basename(file), ifelse(result$valid, "PASS", "FAIL")))
}
```

---

## Test Coverage Checklist

- ✅ Required columns validation
- ✅ Optional columns validation
- ✅ Data type validation (numeric)
- ✅ Single unique value validation (labels, units)
- ✅ Minimum data points per curve
- ✅ Multi-curve support
- ✅ Empty file detection
- ✅ Missing column detection
- ✅ Limit logic validation
- ✅ Formula injection prevention
- ✅ SQL injection detection
- ✅ Boundary tests (exactly 2 points)
- ✅ Complex naming (underscores, dots)
- ✅ NA value handling

---

**Last Updated:** 2025-02-04
