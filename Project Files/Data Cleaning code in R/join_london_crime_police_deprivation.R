library(tidyverse)
library(lubridate)
library(janitor)


data <- read.csv("ADMP assessment Folder/ADMP assessment/clean_all_london_data.csv")
glimpse(data)

social_deprivation <- read.csv("ADMP assessment Folder/ADMP assessment/clean_deprivation.csv")

print(colSums(is.na(social_deprivation)))
print(colSums(is.na(data)))

generate_random_id <- function(n) {
  # Helper function to generate random 68-character strings
  random_strings <- replicate(n, paste0(sample(c(letters, LETTERS, 0:9), 68, replace = TRUE), collapse = ""))
  return(random_strings)
}

replace_missing_crime_data <- function(df) {
  # Find rows where crime_id is NA
  missing_crime_rows <- which(is.na(df$crime_id))
  
  # Generate replacement crime_id values
  df$crime_id[missing_crime_rows] <- generate_random_id(length(missing_crime_rows))
  
  # Replace missing Outcome only for rows where crime_id was also missing
  if ("last_outcome_category" %in% colnames(df)) {
    df$last_outcome_category[missing_crime_rows][is.na(df$last_outcome_category[missing_crime_rows])] <- "no record"
  }
  
  return(df)
}

my <- replace_missing_crime_data(data)
print(colSums(is.na(my)))


join_crime_deprivation <- my %>%
  left_join(social_deprivation %>% group_by(lsoa_code), by = "lsoa_code")

print(colSums(is.na(join_crime_deprivation)))

#view(join_crime_deprivation)


table(join_crime_deprivation$crime_type)
table(join_crime_deprivation$last_outcome_category)
table(join_crime_deprivation$context)
table(join_crime_deprivation$falls_within)
table(data$falls_within)



glimpse(join_crime_deprivation)


police <- read.csv("ADMP assessment Folder/ADMP assessment/cleaned_police_force_strange.csv")
glimpse(police)


join_london_crime_police_deprivation <- join_crime_deprivation %>%
  left_join(police %>% group_by(year_and_month), by = "year_and_month")

glimpse(join_london_crime_police_deprivation)

write_csv(join_london_crime_police_deprivation,"ADMP assessment Folder/ADMP assessment/join_london_crime_police_deprivation.csv")

print(colSums(is.na(join_crime_deprivation)))

unique(join_crime_deprivation$lsoa_name.x)
table(join_crime_deprivation$lsoa_name.x)


display_data_quality_checks <- function(data) {
  cat(" DATA QUALITY CHECKS ===\n\n")
  
  cat(" Dimensions:\n")
  cat("  - Total Rows:    ", nrow(data), "\n")
  cat("  - Total Columns: ", ncol(data), "\n\n")
  
  cat("Missing Values (per column):\n")
  print(colSums(is.na(data)))
  cat("\n")
  
  cat(" Duplicate Rows:\n")
  cat("  - Count: ", nrow(data) - nrow(unique(data)), "\n\n")
  
  cat(" Data Types (per column):\n")
  print(sapply(data, class))
  cat("\n")
  
  cat(" Unique Values (per column):\n")
  print(sapply(data, function(x) length(unique(x))))
  
  cat("\n Data Quality Checks Complete\n")
}

display_data_quality_checks(social_deprivation)
