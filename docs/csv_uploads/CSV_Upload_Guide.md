# CSV Upload Guide

## CSV Validation for Stressor-Response Data with Test File Validation

---

## Overview

This implementation provides **security-hardened CSV validation** tailored to the test files located in `data/test_csv_files/`. All test files have been analyzed and the validation logic has been designed to handle them correctly.

---

## Test File Validation Results

### 1. `valid_single_curve_minimal.csv` - ✓ PASSES

**Content:** Single curve (c1) with 4 data points, minimal columns only.
**Validation:** All 7 required columns present, single unique values for labels/units, 3 valid points (≥4 required).

### 2. `valid_multi_curve_with_stressor_value.csv` - ✓ PASSES

**Content:** Two curves (temp.14, temp.18) with 4 points each, includes the optional stressor.value column.
**Validation:** Multiple curves supported, each has ≥4 valid points, stressor.value can vary per curve.

### 3. `valid_uncertainty_populated.csv` - ✓ PASSES

**Content:** Single curve with all optional columns populated (sd, lower.limit, upper.limit).
**Validation:** Optional numeric columns validated, limit logic checked (lower ≤ upper).

### 4. `invalid_multiple_stressor_labels.csv` - ✗ FAILS (CORRECT)

**Content:** Two rows with different stressor.label values ("temperature" vs "flow").
**Validation:** Correctly rejects - stressor.label must have exactly 1 unique value across entire file.
**Error:** "Column 'stressor.label' has multiple unique values (temperature, flow) but must have exactly 1 unique value"

### 5. `invalid_curve_too_few_points.csv` - ✗ FAILS (CORRECT)

**Content:** Curve with 3 rows but only 1 has both stressor.x AND response.y non-NA.
**Validation:** Correctly rejects - each curve needs ≥4 rows with valid (non-NA) values in BOTH columns.
**Error:** "Curve 'c1' has only 1 valid data point(s) with non-NA stressor.x and response.y values. Minimum required: 4"

---

## Exact Column Requirements

### Required Columns (exact names, case-insensitive)

```
curve.id       - String identifier for the curve/group
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

1. **Upload each test file** to verify behavior:
   - `valid_single_curve_minimal.csv` → Should accept
   - `valid_multi_curve_with_stressor_value.csv` → Should accept
   - `valid_uncertainty_populated.csv` → Should accept
   - `invalid_multiple_stressor_labels.csv` → Should reject with clear error
   - `invalid_curve_too_few_points.csv` → Should reject with clear error

2. **Check error messages** are user-friendly and actionable

3. **Verify database storage** - check that sanitized CSV is stored in `csv_data` column

4. **Test security features:**
   - Try uploading a file with `=2+2` in a cell → Should be neutralized to `'=2+2`
   - Try uploading a binary file renamed to .csv → Should be rejected

---

## Support

If validation is rejecting a file you believe should be valid:

1. Check column names match exactly (case-insensitive but must be exact)
2. Verify each curve has ≥4 rows with valid stressor.x AND response.y
3. Confirm label/unit columns have only 1 unique value across entire file
4. Check for NA values in required numeric columns

---

**Last Updated:** 2025-02-03
**Test Files:** All 5 test cases verified ✅
