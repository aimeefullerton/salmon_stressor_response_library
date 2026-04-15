# nolint start
library(shiny)
library(DBI)
library(openxlsx) # Required for multi-sheet Excel exports

# UPDATED: Now requires `filtered_data` as the second argument
setup_download_csv <- function(output, filtered_data, paginated_data, db, input, session) {

# 1. The "Shopping Cart" for global selections across pages
  selected_tracker <- reactiveVal(character(0))
  
  observe({
    df <- paginated_data()
    req(nrow(df) > 0)
    current_cart <- selected_tracker()
    
  # Check every checkbox on the current page
    for (id in df$article_id) {
      box_val <- input[[paste0("select_article_", id)]]
      if (!is.null(box_val)) {
        if (box_val) {
          # Add to cart if checked
          current_cart <- unique(c(current_cart, as.character(id)))
        } else {
          # Remove from cart if unchecked
          current_cart <- setdiff(current_cart, as.character(id))
        }
      }
    }
    selected_tracker(current_cart)
  })

# Auto-switch the radio button based on if anything is in the cart
  observeEvent(selected_tracker(), {
    if (length(selected_tracker()) > 0) {
      updateRadioButtons(session = session, inputId = "download_option", selected = "selected")
    } else {
      updateRadioButtons(session = session, inputId = "download_option", selected = "filtered")
    }
  })

# Flatten list columns (text[]) for Excel export safety
  flatten_for_export <- function(df) {
    list_cols <- names(df)[sapply(df, is.list)]
    if (length(list_cols) > 0) {
      df[list_cols] <- lapply(df[list_cols], function(col) {
        vapply(col, function(x) {
          if (length(x) == 0 || all(is.na(x))) NA_character_
          else paste(x[!is.na(x)], collapse = ", ")
        }, character(1))
      })
    }
    df
  }

# 2. Build the Multi-Sheet Excel Download
  output$download_csv <- downloadHandler(
    filename = function() {
      prefix <- switch(input$download_option,
        all      = "all_stressor_responses",
        filtered = "filtered_stressor_responses",
        selected = "selected_stressor_responses",
        "download"
      )
      paste0(prefix, "_", Sys.Date(), ".xlsx") # Using Excel extension
    },
    contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    content = function(file) {
      
# Step A: Get the Main Metadata
      df_main <- switch(input$download_option,
        all = tryCatch(
          dbReadTable(db, "stressor_responses"),
          error = function(e) data.frame()
        ),
        
# FULL filtered data instead of paginated
        filtered = filtered_data(), 
        
# Globally selected data
        selected = {
          ids_to_keep <- selected_tracker()
          all_data <- filtered_data() 
          all_data[as.character(all_data$article_id) %in% ids_to_keep, , drop = FALSE]
        },
        data.frame()
      )

# Handle empty downloads gracefully
      if (nrow(df_main) == 0) {
        showNotification("No data available for download.", type = "warning")
        wb <- createWorkbook()
        addWorksheet(wb, "No Data")
        saveWorkbook(wb, file, overwrite = TRUE)
        return()
      }

      df_main <- flatten_for_export(df_main)

# Step B: Initialize Workbook and Add Sheet 1 (Metadata)
      wb <- createWorkbook()
      addWorksheet(wb, "Metadata")
      writeData(wb, "Metadata", df_main)
      
# Step C: Fetch related CSV Data and Add Separate Sheets per Article
      article_ids <- unique(df_main$article_id)
      
      if (length(article_ids) > 0) {
        id_string <- paste(article_ids, collapse = ",")
        
# Safe query to pull matching rows from the csv_data table all at once
        df_csv_data <- tryCatch({
          dbGetQuery(db, sprintf("SELECT * FROM csv_data WHERE article_id IN (%s)", id_string))
        }, error = function(e) {
          data.frame() # Returns empty if table doesn't exist
        })

# Only proceed if actual CSV data exists for these articles
        if (nrow(df_csv_data) > 0) {
          
# Loop through each unique article ID that actually has data
          for (id in unique(df_csv_data$article_id)) {
            
      # 1. Create a safe, short sheet name (Excel limits tabs to 31 characters)
            sheet_name <- paste0("Data - Art ", id)
            
      # 2. Subset the data so it only contains rows for THIS specific article
            article_specific_data <- df_csv_data[df_csv_data$article_id == id, , drop = FALSE]
            
      # 3. Create the new tab and write the isolated data to it
            addWorksheet(wb, sheet_name)
            writeData(wb, sheet_name, article_specific_data)
          }
        }
      }

# Step D: Save and serve the file
      saveWorkbook(wb, file, overwrite = TRUE)
    }
  )
}
# nolint end
