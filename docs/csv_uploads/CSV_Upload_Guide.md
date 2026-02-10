# CSV Upload Guide

## CSV Validation for Stressor-Response Data with Test File Validation

---

## Overview

This implementation provides **security-hardened CSV validation** for the Stressor-Response Function (SRF) data upload system. The validation has been designed and tested against 14 comprehensive test CSV files, located in `data/test_csv_files/`, covering all validation scenarios.

---

A complete set of **14 test CSV files** is provided in the `/data/test_csv_files/` directory:

### ✅ Valid Files (4) - Should PASS

- `valid_complex_multi_curve.csv` - Complex 3-curve scenario
- `valid_multi_curve_with_stressor_value.csv` - Multi-curve support
- `valid_single_curve_minimal.csv` - Basic structure
- `valid_uncertainty_populated.csv` - Optional columns populated

### ❌ Invalid Files (8) - Should FAIL

- `invalid_curve_too_few_points.csv` - Too few valid points
- `invalid_empty_curve_id.csv` - Empty required field
- `invalid_empty_file.csv` - No data rows
- `invalid_limit_logic.csv` - Invalid limit relationship
- `invalid_missing_units_x_column.csv` - Missing required column
- `invalid_multiple_stressor_labels.csv` - Multiple label values
- `invalid_multiple_units_x.csv` - Inconsistent units
- `invalid_non_numeric_stressor_x.csv` - Non-numeric values

### 🛡️ Security Test Files (2)

- `security_formula_injection.csv` - Formula injection test
- `security_sql_injection.csv` - SQL injection pattern test

**📖 See `/docs/csv_uploads/CSV_Testing_Guide.md` for complete details on each test file.**

---

## Exact Column Requirements

### Required Columns (exact names, case-insensitive)

```
curve.id       - String identifier for the curve
stressor.label - Single unique value across entire file (e.g., "temperature")
stressor.x     - Numeric X values (NA allowed in individual rows)
units.x        - Single unique value across entire file (e.g., "degC")
response.label - Single unique value across entire file (e.g., "survival")
response.y     - Numeric Y values (NA allowed in individual rows)
units.y        - Single unique value across entire file (e.g., "percent")
```

### Optional Columns (exact names, case-insensitive)

```
stressor.value - Curve descriptor, can vary per curve (e.g., "14", "constant")
lower.limit    - Lower confidence limit (numeric, NA allowed)
upper.limit    - Upper confidence limit (numeric, NA allowed)
sd             - Standard deviation (numeric, NA allowed)
```

---

## Validation Rules

### 1. Column Structure

- All 7 required columns must be present (exact names, case-insensitive)
- Optional columns detected automatically if present, and added if not present (populated with NA)
- No flexible naming patterns - column names must match exactly

### 2. Data Type Validation

- `curve.id`: String, no empty values allowed
- `stressor.x`: Numeric (NA allowed in rows, but see rule #4)
- `response.y`: Numeric (NA allowed in rows, but see rule #4)
- `sd`, `lower.limit`, `upper.limit`: Numeric, NA allowed
- `stressor.value`: Any type (string or numeric)

### 3. Single Unique Value Validation

These columns must have exactly 1 unique non-NA value across the **entire file**:

- `stressor.label`
- `response.label`
- `units.x`
- `units.y`

**Example - VALID:**

```csv
curve.id,stressor.x,response.y,stressor.label,...
c1,10,0.9,temperature,...
c1,20,0.8,temperature,...  ← Same label ✓
c2,30,0.7,temperature,...  ← Same label ✓
c2,40,0.6,temperature,...  ← Same label ✓
```

**Example - INVALID:**

```csv
curve.id,stressor.x,response.y,stressor.label,...
c1,10,0.9,temperature,...
c1,20,0.8,flow,...         ← Different label ✗
```

### 4. Minimum Data Points Per Curve

Each unique `curve.id` must have at least **4 rows** where BOTH `stressor.x` AND `response.y` are non-NA numeric values.

**Example - VALID:**

```csv
curve.id,stressor.x,response.y
c1,10,0.9    ← Valid point 1
c1,20,0.8    ← Valid point 2
c1,30,0.7    ← Valid point 3
c1,40,0.6    ← Valid point 4 ✓
```

**Example - INVALID:**

```csv
curve.id,stressor.x,response.y
c1,10,0.9    ← Valid point 1
c1,NA,0.8    ← Invalid (NA in stressor.x)
c1,30,NA     ← Invalid (NA in response.y)
             ← Only 1 valid point total ✗
```

### 5. Multi-Curve Support

Multiple curves can exist in one file. Each is validated independently:

```csv
curve.id,stressor.x,response.y,stressor.label,stressor.value,...
temp14,10,0.9,temperature,14,...
temp14,20,0.8,temperature,14,...
temp14,30,0.7,temperature,14,...
temp14,40,0.6,temperature,14,...  ← Curve 1: 4 valid points ✓
temp18,10,0.7,temperature,18,...
temp18,20,0.6,temperature,18,...
temp18,30,0.5,temperature,18,...
temp18,40,0.4,temperature,18,...  ← Curve 2: 4 valid points ✓
```

Note: `stressor.value` can differ between curves, but `stressor.label` must be the same.

### 6. Limit Logic Validation

If both `lower.limit` and `upper.limit` are present and non-NA, then `lower.limit ≤ upper.limit` must be true.

### 7. Addition of Optional Columns for Data Consistency

When a file is uploaded with no or less than all of the optional columns, the missing optional columns are added with NA values. The columns are then reordered to ensure consistent order, with all optional columns on the right.

Uploaded file with no optional columns:

```csv
curve.id,stressor.x,response.y,stressor.label,response.label,units.x,units.y
c1,0.5,92,temperature,survival,degC,percent
c1,1.0,85,temperature,survival,degC,percent
c1,1.5,70,temperature,survival,degC,percent
c1,2.0,66,temperature,survival,degC,percent
```

What is added to the database:

```csv
curve.id,stressor.label,stressor.x,units.x,response.label,response.y,units.y,stressor.value,lower.limit,upper.limit,sd
c1,temperature,0.5,degC,survival,92,percent,NA,NA,NA,NA
c1,temperature,1.0,degC,survival,85,percent,NA,NA,NA,NA
c1,temperature,1.5,degC,survival,70,percent,NA,NA,NA,NA
c1,temperature,2.0,degC,survival,66,percent,NA,NA,NA,NA
```

Uploaded file with partial optional columns:

```csv
curve.id,stressor.x,response.y,sd,stressor.label,response.label,units.x,units.y
c1,10,0.9,0.05,temperature,survival,degC,percent
c1,20,0.8,0.06,temperature,survival,degC,percent
c1,30,0.7,0.07,temperature,survival,degC,percent
c1,40,0.6,0.08,temperature,survival,degC,percent
```

What is added to the database:

```csv
curve.id,stressor.label,stressor.x,units.x,response.label,response.y,units.y,stressor.value,lower.limit,upper.limit,sd
c1,temperature,10,degC,survival,0.9,percent,NA,NA,NA,0.05
c1,temperature,20,degC,survival,0.8,percent,NA,NA,NA,0.06
c1,temperature,30,degC,survival,0.7,percent,NA,NA,NA,0.07
c1,temperature,40,degC,survival,0.6,percent,NA,NA,NA,0.08
```

---

## Security Features

### Formula Injection Prevention

**Threat:** Cells starting with `=`, `+`, `-`, `@` could execute as formulas in Excel.
**Protection:** Automatic neutralization by prefixing with single quote.

```
Original: =2+2
Sanitized: '=2+2
```

### SQL Injection Protection

**Threat:** Malicious SQL commands in CSV content.
**Protection:**

1. Pattern detection (warns if SQL keywords detected)
2. **Parameterized queries** prevent execution (most important!)

Always use:

```r
dbExecute(conn, "INSERT INTO table VALUES ($1)", params = list(csv_text))
```

Never use:

```r
dbExecute(conn, paste0("INSERT INTO table VALUES ('", csv_text, "')"))  # DANGEROUS!
```

### Binary Content Detection

**Threat:** Executables disguised as CSV files.
**Protection:** Rejects files with binary signatures (PE, ELF, ZIP headers, null bytes).

### File Size Limit

**Protection:** 2MB maximum (configurable via `MAX_FILE_SIZE_BYTES`).

---

## Example Valid CSV

```csv
curve.id,stressor.x,response.y,sd,lower.limit,upper.limit,stressor.label,stressor.value,response.label,units.x,units.y
c1,10,0.90,0.05,0.80,1.00,temperature,constant,survival,degC,proportion
c1,15,0.85,0.05,0.75,0.95,temperature,constant,survival,degC,proportion
c1,20,0.70,0.06,0.58,0.82,temperature,constant,survival,degC,proportion
c1,25,0.50,0.07,0.36,0.64,temperature,constant,survival,degC,proportion
```

**Why this passes:**

- ✓ All 7 required columns present
- ✓ All optional columns present
- ✓ `curve.id` has values in all rows
- ✓ `stressor.label` single value ("temperature")
- ✓ `stressor.x` all numeric (10, 15, 20, 25)
- ✓ `units.x` single value ("degC")
- ✓ `response.label` single value ("survival")
- ✓ `response.y` all numeric (0.90, 0.85, 0.70, 0.50)
- ✓ `units.y` single value ("proportion")
- ✓ Curve "c1" has 4 valid points (≥4 required)
- ✓ `lower.limit ≤ upper.limit` in all rows

---

## Common Error Messages

### "Missing required column: 'stressor.x'"

**Cause:** Column name doesn't match exactly (e.g., "stressor" instead of "stressor.x").
**Fix:** Use exact column names: `curve.id`, `stressor.x`, `response.y`, `stressor.label`, `response.label`, `units.x`, `units.y`

### "Column 'stressor.label' has multiple unique values (temperature, flow)"

**Cause:** Different values in the stressor.label column.
**Fix:** All rows must have the same value in stressor.label, response.label, units.x, and units.y columns.

### "Curve 'c1' has only 1 valid data point(s)"

**Cause:** Too many NA values in stressor.x or response.y.
**Fix:** Ensure each curve has at least 4 rows where BOTH stressor.x AND response.y are non-NA numbers.

### "Column 'stressor.x' contains non-numeric values"

**Cause:** Text or special characters in numeric columns.
**Fix:** stressor.x and response.y must contain only numbers or NA.

### "Lower limit exceeds upper limit in rows: 2, 5"

**Cause:** lower.limit > upper.limit in some rows.
**Fix:** Ensure lower.limit ≤ upper.limit in all rows where both are non-NA.

---

## Configuration Options

Located at top of `modules/csv_validation.R`:

```r
# Maximum file size in bytes (2 MB)
MAX_FILE_SIZE_BYTES <- 2 * 1024 * 1024

# Minimum valid data points per curve
MIN_VALID_POINTS_PER_CURVE <- 4

# Allowed MIME types
ALLOWED_MIME_TYPES <- c("text/csv", "application/csv", "text/plain", "application/vnd.ms-excel")
```

---

## Testing

### Manual Testing Steps

1. **Upload each test file** from `/data/test_csv_files/` directory
2. **Verify expected behavior:**
   - Valid files → ✓ Success with metadata
   - Invalid files → ❌ Clear error messages
   - Security files → Appropriate handling
3. **Check error messages** are actionable
4. **Verify database storage** - sanitized CSV in `csv_json` column
5. **Review security features:**
   - Formula injection → Neutralized (prefix with ')
   - SQL injection → Detected and warned (safe with parameterized queries)

### Automated Testing (Optional)

```r
source("csv_validation.R")

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

### Expected Test Results

| Test     | Expected       | Description                                      |
| -------- | -------------- | ------------------------------------------------ |
| valid    | ✅ PASS        | Valid scenarios                                  |
| invalid  | ❌ FAIL        | Invalid scenarios                                |
| security | ❌ FAIL        | Formula injection (fails due to multiple labels) |
| security | ⚠️ PASS + WARN | SQL injection (safe with parameterized queries)  |

---

## Test Coverage

The test suite covers:

- ✅ All required columns
- ✅ All optional columns
- ✅ Single & multi-curve scenarios
- ✅ Data type validation
- ✅ Single unique value validation
- ✅ Minimum point requirements
- ✅ Limit logic validation
- ✅ Security features
- ✅ Boundary conditions
- ✅ Empty file detection
- ✅ Complex naming patterns

---

## Support

If validation is rejecting a file you believe should be valid:

1. Check column names match exactly (case-insensitive but exact)
2. Verify each curve has ≥2 rows with valid stressor.x AND response.y
3. Confirm label/unit columns have only 1 unique value across entire file
4. Check for NA values in required numeric columns
5. Review test files for examples

---

**Last Updated:** 2025-02-06
**Test Files:** 14 comprehensive test cases included
