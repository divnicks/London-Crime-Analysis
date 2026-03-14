library(tidyverse)
library(lubridate)
library(janitor)


crime_police_deprivation <- read.csv("ADMP assessment Folder/ADMP assessment/join_london_crime_police_deprivation.csv")
glimpse(crime_police_deprivation)

    
clean_crime_police_deprivation <- crime_police_deprivation %>% clean_names()

clean_crime_police_deprivation  <- clean_crime_police_deprivation %>%
  distinct(crime_id, .keep_all = TRUE)


solved <- c(
  "Offender given a caution",
  "Offender given a drugs possession warning",
  "Local resolution",
  "Offender sent to prison",
  "Offender given penalty notice",
  "Offender fined",
  "Offender given suspended prison sentence",
  "Offender given conditional discharge",
  "Suspect charged as part of another case",
  "Offender otherwise dealt with",
  "Defendant sent to Crown Court",
  "Offender deprived of property",
  "Offender ordered to pay compensation",
  "Offender given community sentence",
  "Offender given absolute discharge"
)

unsolved <- c(
  "Investigation complete; no suspect identified",
  "Unable to prosecute suspect",
  "Formal action is not in the public interest",
  "Further investigation is not in the public interest",
  "Action to be taken by another organisation",
  "Defendant found not guilty",
  "Court case unable to proceed"
)

unknown <- c(
  "Status update unavailable",
  "Under investigation",
  "Court result unavailable",
  "Awaiting court outcome"
)


clean_crime_police_deprivation  <- clean_crime_police_deprivation  %>%
  mutate(case_status = case_when(
    last_outcome_category %in% solved ~ "Solved",
    last_outcome_category %in% unsolved ~ "Unsolved",
    last_outcome_category %in% unknown ~ "Unknown",
    TRUE ~ "Other"
  ))


clean_crime_police_deprivation  <- clean_crime_police_deprivation  %>%
  mutate(
    longitude = as.numeric(longitude),
    latitude = as.numeric(latitude),
    imd_score = as.numeric(imd_score),
    imd_rank = as.numeric(imd_rank),
    imd_decile = as.numeric(imd_decile),
    income_score = as.numeric(income_score),
    employment_score = as.numeric(employment_score),
    police_officer_strength = as.numeric(police_officer_strength),
    police_staff_strength = as.numeric(police_staff_strength),
    pcso_strength = as.numeric(pcso_strength),
    total_officers = as.numeric(total_officers)
  )

clean_crime_police_deprivation  <- clean_crime_police_deprivation %>%
  mutate(
    crime_type = as.factor(crime_type),
    deprivation_level = factor(deprivation_level, levels = c("Low", "Medium", "High","Very High"), ordered = TRUE),
    case_status = factor(case_status, levels = c("Solved", "Unsolved", "Unknown")),
    location = str_to_title(location)  
  )



clean_crime_police_deprivation <- clean_crime_police_deprivation %>%
  rename(
    lsoa_name = lsoa_name_x,
    time_id = month_x,
    year = year_x,
    police_force_name = reported_by,
    outcome_category = last_outcome_category
  )

clean_crime_police_deprivation <- clean_crime_police_deprivation %>%
  select(
    -lsoa_name_y,
    -year_y,
    -month_y,
    -context,
    -falls_within,
    -income_score,
    -employment_score
  )





clean_crime_police_deprivation <- clean_crime_police_deprivation %>%
  mutate(outcome_category = if_else(is.na(outcome_category), "No record", outcome_category))

View(clean_crime_police_deprivation)

glimpse(clean_crime_police_deprivation)

write_csv(clean_crime_police_deprivation,"clean_london_crime_police_deprivation.csv")


