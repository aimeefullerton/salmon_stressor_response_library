# Return the CSV template as a data frame
get_csv_template <- function() {
  data.frame(
    curve.id = rep("c1", 5),
    stressor.label = rep("temperature", 5),
    stressor.x = c(10, 15, 20, 25, 30),
    units.x = rep("degC", 5),
    response.label = rep("survival", 5),
    response.y = c(0.95, 0.85, 0.70, 0.50, 0.30),
    units.y = rep("proportion", 5),
    stressor.value = rep("constant", 5),
    lower.limit = c(0.90, 0.80, 0.65, 0.45, 0.25),
    upper.limit = c(1.00, 0.90, 0.75, 0.55, 0.35),
    sd = rep(0.05, 5),
    stringsAsFactors = FALSE
  )
}

# Write the template to a CSV file
write_csv_template <- function(file_path) {
  write.csv(get_csv_template(), file_path, row.names = FALSE)
}
