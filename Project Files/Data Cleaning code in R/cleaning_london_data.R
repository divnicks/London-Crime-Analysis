library(tidyverse)
library(lubridate)
library(janitor)
library(stringr)
Sys.setlocale("LC_TIME","English")

all_data <- read.csv("ADMP assessment Folder/ADMP assessment/three_street_data.csv")

clean_data <- all_data %>% clean_names()

london_areas <- c(
  "Barking and Dagenham",
  "Barnet",
  "Bexley",
  "Brent",
  "Bromley",
  "Camden",
  "Croydon",
  "Ealing",
  "Enfield",
  "Greenwich",
  "Hackney",
  "Hammersmith and Fulham",
  "Haringey",
  "Harrow",
  "Havering",
  "Hillingdon",
  "Hounslow",
  "Islington",
  "Kensington and Chelsea",
  "Kingston upon Thames",
  "Lambeth",
  "Lewisham",
  "Merton",
  "Newham",
  "Redbridge",
  "Richmond upon Thames",
  "Southwark",
  "Sutton",
  "Tower Hamlets",
  "Waltham Forest",
  "Wandsworth",
  "Westminster",
  "City of London"
)

london_data <- clean_data %>%
  filter(grepl(paste(london_areas, collapse = "|"), lsoa_name, ignore.case = TRUE))


london_data<-london_data %>%
  mutate(
    month = ym(month),
    year = year(month),
    quarter = quarter(month),
    year_and_month = format_ISO8601(month,precision = "ym"),
    month_name = format(as.Date(month),"%B")
  )



View(london_data)
glimpse(london_data)

summary(london_data)

str(london_data)
glimpse(london_data)


# EDA before cleaning
table(london_data$crime_type)
table(london_data$last_outcome_category)
table(london_data$context)

london_data %>% 
  tabyl(last_outcome_category) %>%
  adorn_totals("col") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting()

london_data %>% 
  tabyl(crime_type) %>%
  adorn_totals("col") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting()


london_data %>% 
  tabyl(crime_type, last_outcome_category) %>%
  adorn_totals("col") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting()


view(london_data)

write_csv(london_data,"london_data.csv")

london <- read.csv("london_data.csv")

glimpse(london)


cleaned_london_data <- london %>%  
  filter(
    !is.na(month),
    !is.na(crime_type)
  )

cleaned_london_data <- cleaned_london_data %>%
  select(
    -context
  )


cleaned_london_data <- cleaned_london_data %>%
  mutate(
    crime_type = str_to_title(str_trim(crime_type)),
    lsoa_name = str_trim(lsoa_name)
  )


cleaned_london_data <- cleaned_london_data %>%
  mutate(crime_id_trimmed = str_trim(crime_id)) %>%  
  group_by(crime_id_trimmed) %>%
  mutate(keep_row = if_else(
    is.na(crime_id) | crime_id_trimmed == "", TRUE, row_number() == 1
  )) %>%
  ungroup() %>%
  filter(keep_row) %>%
  select(-crime_id_trimmed, -keep_row)

view(cleaned_london_data)
glimpse(cleaned_london_data)

write_csv(cleaned_london_data,"ADMP assessment Folder/ADMP assessment/clean_all_london_data.csv")

data <- read.csv("ADMP assessment Folder/ADMP assessment/london_data.csv")

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

display_data_quality_checks(data)



print(colSums(is.na(data)))
print(nrow(data) - nrow(unique(data)))

