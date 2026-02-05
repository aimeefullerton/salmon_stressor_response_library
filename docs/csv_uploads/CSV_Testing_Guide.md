# Manual Validation Verification - Analysis of how each test CSV file would be validated

## Test File Analysis

### 1. valid_single_curve_minimal.csv ✓ SHOULD PASS

**Content:**

```
curve.id,stressor.x,response.y,stressor.label,response.label,units.x,units.y
c1,0.5,92,temperature,survival,degC,percent
c1,1.0,85,temperature,survival,degC,percent
c1,1.5,70,temperature,survival,degC,percent
c1,2.0,66,temperature,survival,degC,percent
```

**Validation Steps:**

1. ✓ Security checks: File is text CSV, no binary content
2. ✓ Column structure: All 7 required columns present
3. ✓ curve.id: All rows have "c1" (no empty values)
4. ✓ stressor.x: All numeric (0.5, 1.0, 1.5)
5. ✓ response.y: All numeric (92, 85, 70)
6. ✓ stressor.label: Single unique value "temperature"
7. ✓ response.label: Single unique value "survival"
8. ✓ units.x: Single unique value "degC"
9. ✓ units.y: Single unique value "percent"
10. ✓ Minimum points: Curve "c1" has 4 valid points (≥ 4 required)

**Result: PASS** ✅

---

### 2. valid_multi_curve_with_stressor_value.csv ✓ SHOULD PASS

**Content:**

```
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

**Validation Steps:**

1. ✓ Security checks: Pass
2. ✓ Column structure: All required + optional columns present
3. ✓ curve.id: All rows have IDs ("temp.14", "temp.18")
4. ✓ stressor.x: All numeric
5. ✓ response.y: All numeric
6. ✓ stressor.label: Single unique value "temperature"
7. ✓ response.label: Single unique value "survival"
8. ✓ units.x: Single unique value "degC"
9. ✓ units.y: Single unique value "percent"
10. ✓ Optional columns: sd, lower.limit, upper.limit have NA (allowed)
11. ✓ stressor.value: Present (14, 18) - different per curve is OK
12. ✓ Minimum points:
    - Curve "temp.14": 4 valid points ✓
    - Curve "temp.18": 4 valid points ✓

**Result: PASS** ✅

---

### 3. valid_uncertainty_populated.csv ✓ SHOULD PASS

**Content:**

```
curve.id,stressor.x,response.y,sd,lower.limit,upper.limit,stressor.label,stressor.value,response.label,units.x,units.y
c1,10,0.90,0.05,0.80,1.00,sediment,10,emergence.probability,percent,probability
c1,20,0.70,0.06,0.58,0.82,sediment,10,emergence.probability,percent,probability
c1,30,0.40,0.08,0.24,0.56,sediment,10,emergence.probability,percent,probability
c1,40,0.20,0.10,0.04,0.24,sediment,10,emergence.probability,percent,probability
```

**Validation Steps:**

1. ✓ Security checks: Pass
2. ✓ Column structure: All columns present
3. ✓ curve.id: All "c1"
4. ✓ stressor.x: All numeric (10, 20, 30)
5. ✓ response.y: All numeric (0.90, 0.70, 0.40)
6. ✓ stressor.label: Single unique value "sediment"
7. ✓ response.label: Single unique value "emergence.probability"
8. ✓ units.x: Single unique value "percent"
9. ✓ units.y: Single unique value "probability"
10. ✓ sd: All numeric (0.05, 0.06, 0.08)
11. ✓ lower.limit: All numeric
12. ✓ upper.limit: All numeric
13. ✓ lower.limit ≤ upper.limit: 0.80 ≤ 1.00 ✓, 0.58 ≤ 0.82 ✓, 0.24 ≤ 0.56 ✓
14. ✓ Minimum points: Curve "c1" has 4 valid points

**Result: PASS** ✅

---

### 4. invalid_multiple_stressor_labels.csv ✗ SHOULD FAIL

**Content:**

```
curve.id,stressor.x,response.y,stressor.label,response.label,units.x,units.y
c1,0.5,92,temperature,survival,degC,percent
c1,1.0,85,flow,survival,degC,percent
```

**Validation Steps:**

1. ✓ Security checks: Pass
2. ✓ Column structure: All required columns present
3. ✓ curve.id: All "c1"
4. ✓ stressor.x: All numeric
5. ✓ response.y: All numeric
6. ✗ stressor.label: **Multiple unique values ("temperature", "flow") - VALIDATION FAILS**
7. ✓ response.label: Single unique value "survival"
8. ✓ units.x: Single unique value "degC"
9. ✓ units.y: Single unique value "percent"

**Error Message:**
"Column 'stressor.label' has multiple unique values (temperature, flow) but must have exactly 1 unique value across the entire file"

**Result: FAIL** ❌ (as expected)

---

### 5. invalid_curve_too_few_points.csv ✗ SHOULD FAIL

**Content:**

```
curve.id,stressor.x,response.y,stressor.label,response.label,units.x,units.y
c1,0.5,92,temperature,survival,degC,percent
c1,NA,85,temperature,survival,degC,percent
c1,1.5,NA,temperature,survival,degC,percent
```

**Validation Steps:**

1. ✓ Security checks: Pass
2. ✓ Column structure: All required columns present
3. ✓ curve.id: All "c1"
4. ✓ stressor.x: Numeric + NA allowed
5. ✓ response.y: Numeric + NA allowed
6. ✓ stressor.label: Single unique value "temperature"
7. ✓ response.label: Single unique value "survival"
8. ✓ units.x: Single unique value "degC"
9. ✓ units.y: Single unique value "percent"
10. ✗ Minimum points check:
    - Row 1: stressor.x = 0.5 ✓, response.y = 92 ✓ → VALID
    - Row 2: stressor.x = NA ✗, response.y = 85 ✓ → INVALID (NA in stressor.x)
    - Row 3: stressor.x = 1.5 ✓, response.y = NA ✗ → INVALID (NA in response.y)
    - **Total valid points: 1 (requires minimum 4) - VALIDATION FAILS**

**Error Message:**
"Curve 'c1' has only 1 valid data point(s) with non-NA stressor.x and response.y values. Minimum required: 4"

**Result: FAIL** ❌ (as expected)

---

## Summary of Validation Logic

### Required Columns (exact names, case-insensitive):

1. `curve.id` - String identifier, no empty values
2. `stressor.x` - Numeric values (NA allowed in individual rows)
3. `response.y` - Numeric values (NA allowed in individual rows)
4. `stressor.label` - Must have exactly 1 unique non-NA value across entire file
5. `response.label` - Must have exactly 1 unique non-NA value across entire file
6. `units.x` - Must have exactly 1 unique non-NA value across entire file
7. `units.y` - Must have exactly 1 unique non-NA value across entire file

### Optional Columns (exact names, case-insensitive):

- `sd` - Numeric, NA allowed
- `lower.limit` - Numeric, NA allowed
- `upper.limit` - Numeric, NA allowed
- `stressor.value` - String or numeric, can vary per curve

### Additional Validation Rules:

1. **Minimum data points:** Each curve must have at least 4 rows where BOTH stressor.x AND response.y are non-NA numbers
2. **Limit logic:** If both lower.limit and upper.limit are present and non-NA, lower.limit must be ≤ upper.limit
3. **Multi-curve support:** Multiple curves can exist in one file (identified by different curve.id values)

### Security Features:

- Formula injection prevention (=, +, -, @ prefixes neutralized)
- Binary content detection (rejects executables)
- SQL injection pattern detection (warns but allows with parameterized queries)
- File size limit (2MB max)
- UTF-8 encoding validation

---

## Test Results Summary

| Test File                                 | Expected | Actual | Status |
| ----------------------------------------- | -------- | ------ | ------ |
| valid_single_curve_minimal.csv            | PASS     | PASS   | ✅     |
| valid_multi_curve_with_stressor_value.csv | PASS     | PASS   | ✅     |
| valid_uncertainty_populated.csv           | PASS     | PASS   | ✅     |
| invalid_multiple_stressor_labels.csv      | FAIL     | FAIL   | ✅     |
| invalid_curve_too_few_points.csv          | FAIL     | FAIL   | ✅     |

**Result: 5/5 tests would pass correctly**
