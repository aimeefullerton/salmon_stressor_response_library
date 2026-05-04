# nolint start
update_filters_server <- function(input, output, session, data, db) {
  
  print("🚀 MODULE STARTED: update_filters_server")
  print(paste("📊 Data rows received by module:", nrow(data)))

  # 1. Isolate just the species column
  species_raw <- data$species_common_name
  species_clean <- species_raw[!is.na(species_raw) & species_raw != ""]
  
  # 2. Flatten the comma-separated strings
  parts <- unlist(lapply(species_clean, function(x) trimws(strsplit(as.character(x), ",")[[1]])))
  unique_species <- sort(unique(parts[parts != "" & parts != "NA" & parts != "NULL"]))
  
  print(paste("🐟 Found", length(unique_species), "unique species tags. First few:"))
  print(head(unique_species))

  # 3. Send to the UI IMMEDIATELY
  print("📤 Sending updatePickerInput command for 'species' dropdown...")
  
  updatePickerInput(session, inputId = "species", choices = unique_species)
  
  print("✅ Update command sent to UI.")
}
# nolint end
