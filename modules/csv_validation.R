# nolint start

# SECURE CSV Validation for Stressor-Response Function (SRF) Data
# This module provides comprehensive validation + security hardening for CSV uploads
#
# Security Features:
#   - Formula/CSV injection prevention (neutralizes =, +, -, @, etc.)
#   - Binary content detection (rejects executables disguised as CSV)
#   - UTF-8 encoding validation
#   - MIME type verification
#   - SQL injection pattern detection
#   - File size limits
#
# Integrated with error_handling.R for consistent user messaging

# ============================================================================
# CONFIGURATION
# ============================================================================

# Maximum file size in bytes (2 MB)
MAX_FILE_SIZE_BYTES <- 2 * 1024 * 1024

# Security: Dangerous prefixes that trigger formula injection in Excel/Google Sheets
DANGEROUS_FORMULA_PREFIXES <- c("=", "+", "-", "@", "\t", "\r")

# Allowed MIME types for CSV uploads
ALLOWED_MIME_TYPES <- c("text/csv", "application/csv", "text/plain", "application/vnd.ms-excel")

# ============================================================================
# SECURITY LAYER 1: FILE-LEVEL VALIDATION
# ============================================================================

#' Validate File Extension
#'
#' @param file_input Shiny file input object
#' @return List with $valid (logical) and $message (character)
validate_file_extension <- function(file_input) {
  file_name <- file_input$name
  ext <- tolower(tools::file_ext(file_name))

  if (ext != "csv") {
    return(list(
      valid = FALSE,
      message = sprintf(
        "Invalid file extension '.%s'. Only .csv files are permitted.",
        ext
      )
    ))
  }

  list(valid = TRUE, message = "")
}

#' Validate MIME Type
#'
#' @param file_input Shiny file input object
#' @return List with $valid (logical) and $message (character)
validate_mime_type <- function(file_input) {
  mime_type <- file_input$type

  if (is.null(mime_type) || !mime_type %in% ALLOWED_MIME_TYPES) {
    return(list(
      valid = FALSE,
      message = sprintf(
        "Invalid file type detected (MIME: %s). Only CSV files are accepted.",
        ifelse(is.null(mime_type), "unknown", mime_type)
      )
    ))
  }

  list(valid = TRUE, message = "")
}

#' Detect Binary Content in File
#'
#' Security: CSV files should be text-only. Binary content suggests malicious payload.
#'
#' @param file_path Path to uploaded file
#' @return List with $valid (logical) and $message (character)
detect_binary_content <- function(file_path) {
  # Read first 10KB as raw bytes
  max_bytes_to_check <- min(10240, file.info(file_path)$size)
  raw_bytes <- readBin(file_path, "raw", n = max_bytes_to_check)

  # Check for null bytes (strong indicator of binary content)
  if (any(raw_bytes == as.raw(0x00))) {
    return(list(
      valid = FALSE,
      message = "File contains binary content. Please upload a text-based CSV file."
    ))
  }

  # Check for executable signatures
  # PE header (Windows .exe): "MZ"
  if (length(raw_bytes) >= 2 && raw_bytes[1] == as.raw(0x4D) && raw_bytes[2] == as.raw(0x5A)) {
    return(list(
      valid = FALSE,
      message = "File appears to be an executable. Only CSV files are permitted."
    ))
  }

  # ELF header (Unix executable)
  if (length(raw_bytes) >= 4 &&
    raw_bytes[1] == as.raw(0x7F) &&
    raw_bytes[2] == as.raw(0x45) &&
    raw_bytes[3] == as.raw(0x4C) &&
    raw_bytes[4] == as.raw(0x46)) {
    return(list(
      valid = FALSE,
      message = "File appears to be an executable. Only CSV files are permitted."
    ))
  }

  # ZIP header: "PK"
  if (length(raw_bytes) >= 2 && raw_bytes[1] == as.raw(0x50) && raw_bytes[2] == as.raw(0x4B)) {
    return(list(
      valid = FALSE,
      message = "File appears to be a ZIP archive. Please upload an uncompressed CSV file."
    ))
  }

  list(valid = TRUE, message = "")
}

#' Validate File Encoding
#'
#' @param file_path Path to uploaded file
#' @return List with $valid (logical) and $message (character)
validate_encoding <- function(file_path) {
  tryCatch(
    {
      lines <- readLines(file_path, encoding = "UTF-8", warn = FALSE, n = 100)

      if (length(lines) == 0) {
        return(list(
          valid = FALSE,
          message = "File appears to be empty."
        ))
      }

      list(valid = TRUE, message = "")
    },
    error = function(e) {
      list(
        valid = FALSE,
        message = sprintf(
          "File encoding error. Please ensure the file is saved as UTF-8 text. Error: %s",
          conditionMessage(e)
        )
      )
    }
  )
}

#' Comprehensive File Security Validation
#'
#' @param file_input Shiny file input object
#' @return List with $valid (logical) and $message (character)
validate_file_security <- function(file_input) {
  # Extension check
  ext_check <- validate_file_extension(file_input)
  if (!ext_check$valid) {
    return(ext_check)
  }

  # MIME type check
  mime_check <- validate_mime_type(file_input)
  if (!mime_check$valid) {
    return(mime_check)
  }

  # Binary content detection
  binary_check <- detect_binary_content(file_input$datapath)
  if (!binary_check$valid) {
    return(binary_check)
  }

  # Encoding validation
  encoding_check <- validate_encoding(file_input$datapath)
  if (!encoding_check$valid) {
    return(encoding_check)
  }

  list(valid = TRUE, message = "Security validation passed")
}

# ============================================================================
# SECURITY LAYER 2: CONTENT SECURITY
# ============================================================================

#' Sanitize CSV Cell Values Against Formula Injection
#'
#' Prevents CSV/Formula injection by neutralizing dangerous prefixes.
#' Any cell starting with =, +, -, @, tab, or carriage return will be
#' prefixed with a single quote to force literal interpretation.
#'
#' @param df Data frame to sanitize
#' @return Sanitized data frame
sanitize_csv_cells <- function(df) {
  df[] <- lapply(df, function(col) {
    if (is.character(col)) {
      col <- sapply(col, function(cell_value) {
        if (is.na(cell_value) || nchar(trimws(cell_value)) == 0) {
          return(cell_value)
        }

        trimmed <- trimws(cell_value)
        is_dangerous <- any(sapply(DANGEROUS_FORMULA_PREFIXES, function(prefix) {
          startsWith(trimmed, prefix)
        }))

        if (is_dangerous) {
          # Neutralize by prefixing with single quote
          return(paste0("'", cell_value))
        }

        cell_value
      }, USE.NAMES = FALSE)
    }
    col
  })

  df
}

#' Check for Suspicious Patterns
#'
#' Scans for SQL injection, XSS, and code execution attempts
#'
#' @param df Data frame to check
#' @return List with $valid (logical) and $warnings (list)
check_suspicious_patterns <- function(df) {
  warnings <- list()

  # Patterns indicating injection attempts
  suspicious_patterns <- c(
    "(?i)(DROP|DELETE|TRUNCATE)\\s+(TABLE|DATABASE)", # SQL injection
    "(?i)UNION\\s+SELECT", # SQL injection
    "(?i)<script[^>]*>", # XSS
    "(?i)javascript:", # JavaScript injection
    "(?i)eval\\s*\\(", # Code execution
    "(?i)system\\s*\\(", # System command
    "(?i)exec\\s*\\(" # Code execution
  )

  for (col_name in colnames(df)) {
    col <- df[[col_name]]
    if (is.character(col)) {
      for (pattern in suspicious_patterns) {
        matches <- grep(pattern, col, value = FALSE)
        if (length(matches) > 0) {
          warnings[[length(warnings) + 1]] <- sprintf(
            "Column '%s' contains suspicious patterns in rows %s",
            col_name,
            paste(head(matches, 5), collapse = ", ")
          )
        }
      }
    }
  }

  list(
    valid = length(warnings) == 0,
    warnings = warnings
  )
}

# ============================================================================
# DOMAIN VALIDATION: COLUMN STRUCTURE
# ============================================================================

#' Identify Column by Naming Pattern
#'
#' Finds columns matching patterns like <name>.x, <name>.label, etc.
#'
#' @param col_names Vector of column names (lowercase)
#' @param pattern Regex pattern to match
#' @return Matched column name or NA
find_column_by_pattern <- function(col_names, pattern) {
  matches <- grep(pattern, col_names, value = TRUE, ignore.case = TRUE)
  if (length(matches) > 0) {
    return(matches[1]) # Return first match
  }
  NA_character_
}

#' Validate CSV Column Structure
#'
#' New requirements:
#' Required: curve.id, <stressor>.x, <response>.y, <stressor>.label,
#'           <response>.label, units.x, units.y
#' Optional: lower.limit, upper.limit, sd, stressor.value
#'
#' @param df Data frame from CSV
#' @return List with $valid, $message, $col_map, $issues
validate_csv_columns <- function(df) {
  col_names <- tolower(trimws(colnames(df)))
  issues <- list()

  # Initialize column map
  col_map <- list(
    curve_id = NA_character_,
    stressor_x = NA_character_,
    response_y = NA_character_,
    stressor_label = NA_character_,
    response_label = NA_character_,
    units_x = NA_character_,
    units_y = NA_character_,
    lower_limit = NA_character_,
    upper_limit = NA_character_,
    sd = NA_character_,
    stressor_value = NA_character_
  )

  # ---- Required Column 1: curve.id ----
  curve_id_matches <- grep("^curve\\.id$", col_names, value = TRUE, ignore.case = TRUE)
  if (length(curve_id_matches) > 0) {
    col_map$curve_id <- curve_id_matches[1]
  } else {
    issues[[length(issues) + 1]] <- "Missing required column: 'curve.id'"
  }

  # ---- Required Column 2: <stressor>.x (any name ending in .x) ----
  x_col <- find_column_by_pattern(col_names, "\\.x$")
  if (!is.na(x_col)) {
    col_map$stressor_x <- x_col
  } else {
    issues[[length(issues) + 1]] <- "Missing required column: <stressor-name>.x (e.g., 'temperature.x')"
  }

  # ---- Required Column 3: <response>.y (any name ending in .y) ----
  y_col <- find_column_by_pattern(col_names, "\\.y$")
  if (!is.na(y_col)) {
    col_map$response_y <- y_col
  } else {
    issues[[length(issues) + 1]] <- "Missing required column: <response-name>.y (e.g., 'survival.y')"
  }

  # ---- Required Column 4: <stressor>.label ----
  stressor_label_col <- find_column_by_pattern(col_names, "\\.label$")
  if (!is.na(stressor_label_col)) {
    # Ensure it's a stressor label (not response label)
    # We'll accept the first .label column as stressor.label
    col_map$stressor_label <- stressor_label_col
  } else {
    issues[[length(issues) + 1]] <- "Missing required column: <stressor-name>.label (e.g., 'temperature.label')"
  }

  # ---- Required Column 5: <response>.label ----
  # Find second .label column (or if only one, we'll need explicit response.label)
  label_cols <- grep("\\.label$", col_names, value = TRUE, ignore.case = TRUE)
  if (length(label_cols) >= 2) {
    col_map$response_label <- label_cols[2]
  } else if (length(label_cols) == 1) {
    # Only one .label column - user needs to provide both
    issues[[length(issues) + 1]] <- "Missing required column: <response-name>.label (need both stressor.label and response.label)"
  } else {
    issues[[length(issues) + 1]] <- "Missing required columns: <stressor-name>.label and <response-name>.label"
  }

  # ---- Required Column 6: units.x ----
  units_x_matches <- grep("^units\\.x$", col_names, value = TRUE, ignore.case = TRUE)
  if (length(units_x_matches) > 0) {
    col_map$units_x <- units_x_matches[1]
  } else {
    issues[[length(issues) + 1]] <- "Missing required column: 'units.x'"
  }

  # ---- Required Column 7: units.y ----
  units_y_matches <- grep("^units\\.y$", col_names, value = TRUE, ignore.case = TRUE)
  if (length(units_y_matches) > 0) {
    col_map$units_y <- units_y_matches[1]
  } else {
    issues[[length(issues) + 1]] <- "Missing required column: 'units.y'"
  }

  # ---- Optional Columns ----
  lower_limit_matches <- grep("^lower\\.limit$", col_names, value = TRUE, ignore.case = TRUE)
  if (length(lower_limit_matches) > 0) {
    col_map$lower_limit <- lower_limit_matches[1]
  }

  upper_limit_matches <- grep("^upper\\.limit$", col_names, value = TRUE, ignore.case = TRUE)
  if (length(upper_limit_matches) > 0) {
    col_map$upper_limit <- upper_limit_matches[1]
  }

  sd_matches <- grep("^sd$", col_names, value = TRUE, ignore.case = TRUE)
  if (length(sd_matches) > 0) {
    col_map$sd <- sd_matches[1]
  }

  stressor_value_matches <- grep("^stressor\\.value$", col_names, value = TRUE, ignore.case = TRUE)
  if (length(stressor_value_matches) > 0) {
    col_map$stressor_value <- stressor_value_matches[1]
  }

  # Return validation result
  if (length(issues) > 0) {
    return(list(
      valid = FALSE,
      message = "Column structure validation failed",
      col_map = NULL,
      issues = issues
    ))
  }

  list(
    valid = TRUE,
    message = "Column structure validated",
    col_map = col_map,
    issues = list()
  )
}

# ============================================================================
# DOMAIN VALIDATION: DATA CONTENT
# ============================================================================

#' Validate Numeric Column
#'
#' @param col Vector to validate
#' @param col_name Column name for error messages
#' @param allow_na Whether to allow NA values
#' @return List with $valid and $issues
validate_numeric_column <- function(col, col_name, allow_na = FALSE) {
  issues <- list()

  # Count empty/NA values
  empty_count <- sum(is.na(col) | col == "")
  if (empty_count > 0 && !allow_na) {
    issues[[length(issues) + 1]] <- sprintf(
      "Column '%s' has %d empty or missing values (required to be numeric)",
      col_name, empty_count
    )
  }

  # Try to convert to numeric
  suppressWarnings({
    numeric_col <- as.numeric(col)
  })

  # Find non-numeric values
  if (allow_na) {
    non_numeric_indices <- which(is.na(numeric_col) & !is.na(col) & col != "")
  } else {
    non_numeric_indices <- which(is.na(numeric_col) & !is.na(col))
  }

  if (length(non_numeric_indices) > 0) {
    non_numeric_values <- unique(col[non_numeric_indices])
    issues[[length(issues) + 1]] <- sprintf(
      "Column '%s' contains non-numeric values: %s (in rows %s)",
      col_name,
      paste(head(non_numeric_values, 5), collapse = ", "),
      paste(head(non_numeric_indices, 10), collapse = ", ")
    )
  }

  list(valid = length(issues) == 0, issues = issues)
}

#' Validate Single Unique Value in Column
#'
#' Validates that column has exactly 1 unique non-NA value across entire file
#'
#' @param col Vector to validate
#' @param col_name Column name
#' @return List with $valid and $issues
validate_single_unique_value <- function(col, col_name) {
  issues <- list()

  # Get unique non-NA values
  unique_vals <- unique(col[!is.na(col) & col != ""])

  if (length(unique_vals) == 0) {
    issues[[length(issues) + 1]] <- sprintf(
      "Column '%s' has no non-NA values (required to have exactly 1 unique value)",
      col_name
    )
  } else if (length(unique_vals) > 1) {
    issues[[length(issues) + 1]] <- sprintf(
      "Column '%s' has multiple unique values (%s) but must have exactly 1 unique value across the entire file",
      col_name,
      paste(head(unique_vals, 5), collapse = ", ")
    )
  }

  list(valid = length(issues) == 0, issues = issues)
}

#' Validate CSV Data Content
#'
#' @param df Data frame (with normalized lowercase column names)
#' @param col_map Column mapping from validate_csv_columns
#' @return List with $valid, $message, $issues
validate_csv_data <- function(df, col_map) {
  issues <- list()

  # Normalize column names
  df_normalized <- df
  colnames(df_normalized) <- tolower(trimws(colnames(df)))

  # ---- Validate curve.id (string, required) ----
  if (!is.na(col_map$curve_id)) {
    curve_id_col <- df_normalized[[col_map$curve_id]]
    empty_count <- sum(is.na(curve_id_col) | curve_id_col == "")
    if (empty_count > 0) {
      issues[[length(issues) + 1]] <- sprintf(
        "Column '%s' has %d empty values (all rows must have a curve ID)",
        col_map$curve_id, empty_count
      )
    }
  }

  # ---- Validate <stressor>.x (numeric, required) ----
  if (!is.na(col_map$stressor_x)) {
    x_check <- validate_numeric_column(df_normalized[[col_map$stressor_x]], col_map$stressor_x, allow_na = FALSE)
    if (!x_check$valid) {
      issues <- c(issues, x_check$issues)
    }
  }

  # ---- Validate <response>.y (numeric, required) ----
  if (!is.na(col_map$response_y)) {
    y_check <- validate_numeric_column(df_normalized[[col_map$response_y]], col_map$response_y, allow_na = FALSE)
    if (!y_check$valid) {
      issues <- c(issues, y_check$issues)
    }
  }

  # ---- Validate <stressor>.label (must have exactly 1 unique non-NA value) ----
  if (!is.na(col_map$stressor_label)) {
    label_check <- validate_single_unique_value(df_normalized[[col_map$stressor_label]], col_map$stressor_label)
    if (!label_check$valid) {
      issues <- c(issues, label_check$issues)
    }
  }

  # ---- Validate <response>.label (must have exactly 1 unique non-NA value) ----
  if (!is.na(col_map$response_label)) {
    label_check <- validate_single_unique_value(df_normalized[[col_map$response_label]], col_map$response_label)
    if (!label_check$valid) {
      issues <- c(issues, label_check$issues)
    }
  }

  # ---- Validate units.x (must have exactly 1 unique non-NA value) ----
  if (!is.na(col_map$units_x)) {
    units_check <- validate_single_unique_value(df_normalized[[col_map$units_x]], col_map$units_x)
    if (!units_check$valid) {
      issues <- c(issues, units_check$issues)
    }
  }

  # ---- Validate units.y (must have exactly 1 unique non-NA value) ----
  if (!is.na(col_map$units_y)) {
    units_check <- validate_single_unique_value(df_normalized[[col_map$units_y]], col_map$units_y)
    if (!units_check$valid) {
      issues <- c(issues, units_check$issues)
    }
  }

  # ---- Validate Optional Columns (numeric, NA allowed) ----
  if (!is.na(col_map$lower_limit)) {
    limit_check <- validate_numeric_column(df_normalized[[col_map$lower_limit]], col_map$lower_limit, allow_na = TRUE)
    if (!limit_check$valid) {
      issues <- c(issues, limit_check$issues)
    }
  }

  if (!is.na(col_map$upper_limit)) {
    limit_check <- validate_numeric_column(df_normalized[[col_map$upper_limit]], col_map$upper_limit, allow_na = TRUE)
    if (!limit_check$valid) {
      issues <- c(issues, limit_check$issues)
    }
  }

  if (!is.na(col_map$sd)) {
    sd_check <- validate_numeric_column(df_normalized[[col_map$sd]], col_map$sd, allow_na = TRUE)
    if (!sd_check$valid) {
      issues <- c(issues, sd_check$issues)
    }
  }

  # ---- Validate stressor.value (string or numeric, optional) ----
  # No strict validation needed - can be any type

  # ---- Check logical relationship: lower.limit <= upper.limit ----
  if (!is.na(col_map$lower_limit) && !is.na(col_map$upper_limit)) {
    suppressWarnings({
      lower_limits <- as.numeric(df_normalized[[col_map$lower_limit]])
      upper_limits <- as.numeric(df_normalized[[col_map$upper_limit]])
    })

    invalid_rows <- which(!is.na(lower_limits) & !is.na(upper_limits) & lower_limits > upper_limits)
    if (length(invalid_rows) > 0) {
      issues[[length(issues) + 1]] <- sprintf(
        "Lower limit exceeds upper limit in rows: %s",
        paste(head(invalid_rows, 10), collapse = ", ")
      )
    }
  }

  # Return result
  if (length(issues) > 0) {
    return(list(
      valid = FALSE,
      message = sprintf("Data validation failed with %d issue(s)", length(issues)),
      issues = issues
    ))
  }

  list(
    valid = TRUE,
    message = "Data validation passed",
    issues = list()
  )
}

# ============================================================================
# MAIN VALIDATION FUNCTION
# ============================================================================

#' Comprehensive CSV Upload Validation (Security + Domain)
#'
#' This is the primary function called by your Shiny app.
#' Integrates with error_handling.R for consistent error messaging.
#'
#' @param file_input Shiny file input object
#' @return List with:
#'   - $valid (logical): Whether validation passed
#'   - $message (character): Summary message
#'   - $data (data.frame): Sanitized data if valid, NULL otherwise
#'   - $col_map (list): Column mapping if valid, NULL otherwise
#'   - $all_issues (list): All validation issues
#'   - $security_warnings (list): Security-specific warnings
validate_csv_upload <- function(file_input) {
  # ---- Check if file exists ----
  if (is.null(file_input)) {
    return(list(
      valid = FALSE,
      message = "No CSV file selected",
      data = NULL,
      col_map = NULL,
      all_issues = list("No CSV file selected. Please upload a CSV file."),
      security_warnings = list()
    ))
  }

  file_path <- file_input$datapath
  if (!file.exists(file_path)) {
    return(list(
      valid = FALSE,
      message = "File does not exist",
      data = NULL,
      col_map = NULL,
      all_issues = list("File does not exist. Please try uploading again."),
      security_warnings = list()
    ))
  }

  # ---- Check file size ----
  file_size <- file.info(file_path)$size
  if (file_size > MAX_FILE_SIZE_BYTES) {
    return(list(
      valid = FALSE,
      message = "File too large",
      data = NULL,
      col_map = NULL,
      all_issues = list(sprintf(
        "File size (%.2f MB) exceeds the 2 MB limit.",
        file_size / (1024 * 1024)
      )),
      security_warnings = list()
    ))
  }

  # ---- SECURITY LAYER 1: File-level security ----
  security_check <- validate_file_security(file_input)
  if (!security_check$valid) {
    return(list(
      valid = FALSE,
      message = "Security validation failed",
      data = NULL,
      col_map = NULL,
      all_issues = list(security_check$message),
      security_warnings = list()
    ))
  }

  # ---- Parse CSV ----
  df <- tryCatch(
    {
      read.csv(file_path, stringsAsFactors = FALSE, strip.white = TRUE)
    },
    error = function(e) {
      return(list(
        valid = FALSE,
        message = "Failed to read CSV",
        data = NULL,
        col_map = NULL,
        all_issues = list(sprintf(
          "Failed to read CSV file: %s. Ensure the file is a valid CSV format.",
          conditionMessage(e)
        )),
        security_warnings = list()
      ))
    }
  )

  # Check if CSV read failed
  if (is.list(df) && !is.data.frame(df)) {
    return(df) # Return error from tryCatch
  }

  # ---- Check if empty ----
  if (nrow(df) == 0) {
    return(list(
      valid = FALSE,
      message = "CSV is empty",
      data = NULL,
      col_map = NULL,
      all_issues = list("CSV file is empty. Please include at least one data row."),
      security_warnings = list()
    ))
  }

  # ---- DOMAIN VALIDATION: Column structure ----
  col_check <- validate_csv_columns(df)
  if (!col_check$valid) {
    return(list(
      valid = FALSE,
      message = col_check$message,
      data = NULL,
      col_map = NULL,
      all_issues = col_check$issues,
      security_warnings = list()
    ))
  }

  col_map <- col_check$col_map

  # ---- SECURITY LAYER 2: Check for suspicious patterns ----
  pattern_check <- check_suspicious_patterns(df)
  security_warnings <- pattern_check$warnings

  # ---- SECURITY LAYER 3: Sanitize against formula injection ----
  df_sanitized <- sanitize_csv_cells(df)

  # ---- DOMAIN VALIDATION: Data content ----
  data_check <- validate_csv_data(df_sanitized, col_map)

  if (!data_check$valid) {
    return(list(
      valid = FALSE,
      message = data_check$message,
      data = NULL,
      col_map = col_map,
      all_issues = data_check$issues,
      security_warnings = security_warnings
    ))
  }

  # ---- SUCCESS ----
  return(list(
    valid = TRUE,
    message = "CSV validation passed",
    data = df_sanitized,
    col_map = col_map,
    all_issues = list(),
    security_warnings = security_warnings
  ))
}

# ============================================================================
# HELPER FUNCTIONS FOR ERROR HANDLING INTEGRATION
# ============================================================================

#' Get User-Friendly Error Message for CSV Upload
#'
#' Integrates with error_handling.R
#' Enhanced version with guidance specific to new column requirements
#'
#' @param validation_result Result from validate_csv_upload()
#' @return List with $message and $issues
get_csv_error_message <- function(validation_result) {
  if (validation_result$valid) {
    return(list(
      message = "CSV validation passed",
      issues = list()
    ))
  }

  message <- validation_result$message
  issues <- validation_result$all_issues %||% list()

  # Add helpful guidance based on common issues
  guidance <- ""

  if (length(issues) > 0) {
    if (any(grepl("Missing required column", issues, ignore.case = TRUE))) {
      guidance <- paste0(
        "\n\n<strong>How to fix:</strong> Ensure your CSV has these required columns:\n",
        "• curve.id (curve/group identifier)\n",
        "• <stressor-name>.x (e.g., 'temperature.x') - numeric values\n",
        "• <response-name>.y (e.g., 'survival.y') - numeric values\n",
        "• <stressor-name>.label (e.g., 'temperature.label') - single unique value\n",
        "• <response-name>.label (e.g., 'survival.label') - single unique value\n",
        "• units.x - units for X values (single unique value)\n",
        "• units.y - units for Y values (single unique value)\n",
        "\nOptional columns: lower.limit, upper.limit, sd, stressor.value"
      )
    } else if (any(grepl("non-numeric", issues, ignore.case = TRUE))) {
      guidance <- "\n\n<strong>How to fix:</strong> Ensure .x and .y columns contain only numbers (no text or special characters except decimals)"
    } else if (any(grepl("exactly 1 unique", issues, ignore.case = TRUE))) {
      guidance <- "\n\n<strong>How to fix:</strong> Label and unit columns must have the same value in every row (exactly 1 unique non-NA value)"
    } else if (any(grepl("empty", issues, ignore.case = TRUE))) {
      guidance <- "\n\n<strong>How to fix:</strong> Fill in all required fields. curve.id and numeric columns cannot have empty values."
    }
  }

  list(
    message = paste0(message, guidance),
    issues = issues
  )
}

# nolint end
