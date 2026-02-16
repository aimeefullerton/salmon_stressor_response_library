# Return the CSV template as a data frame
get_csv_template <- function() {
  data.frame(
    curve.id = rep("c1", 5),
    stressor.label = rep("temperature", 5),
    stressor.x = c(10, 15, 20, 25, 30),
    stressor.units = rep("degC", 5),
    response.label = rep("survival", 5),
    response.y = c(0.95, 0.85, 0.70, 0.50, 0.20),
    response.units = rep("proportion", 5),
    lower.limit = c(0.90, 0.80, 0.65, 0.45, 0.15),
    upper.limit = c(1.00, 0.90, 0.75, 0.55, 0.25),
    sd = rep(0.05, 5),
    stringsAsFactors = FALSE
  )
}

# Write the template to a CSV file
write_csv_template <- function(file_path) {
  write.csv(get_csv_template(), file_path, row.names = FALSE)
}
