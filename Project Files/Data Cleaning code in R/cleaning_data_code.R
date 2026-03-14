library(tidyverse)
library(lubridate)
library(janitor)
Sys.setlocale("LC_TIME","English")

merged_crime_data <- read.csv("merged_crime_2015_2025.csv")
outcome_data <- read.csv("merged_outcomes_2015_2025.csv")

glimpse(merge_crime_data)
cleaned_crime_data <- merged_crime_data %>% clean_names()
clean_outcome_data <- outcome_data %>%clean_names()


cleaned_crime_data <- cleaned_crime_data %>%  
  filter(
    !is.na(crime_id),
    !is.na(latitude),
    !is.na(longitude),
    !is.na(month),
    !is.na(crime_type)
  )

clean_outcome_data <- clean_outcome_data %>%
  filter(
    !is.na(crime_id),
    !is.na(longitude),
    !is.na(latitude),
    !is.na(lsoa_code),
    !is.na(lsoa_name)
  )


cleaned_crime_data <- cleaned_crime_data %>%
  mutate(
    crime_type = str_to_title(str_trim(crime_type)),
    context = ifelse(is.na(context),"Unknown",context),
    location = str_to_title(str_trim(location)),
    lsoa_name = str_trim(lsoa_name)
  )

cleaned_crime_data<-cleaned_crime_data %>%
  mutate(
    month = ym(month),
    year = year(month),
    quarter = quarter(month),
    year_and_month = format_ISO8601(month,precision = "ym"),
    month_name = format(as.Date(month),"%B")
  )

cleaned_crime_data <- cleaned_crime_data %>%
  distinct(crime_id, .keep_all = TRUE)

clean_outcome_data <- clean_outcome_data %>%
  distinct(crime_id, .keep_all = TRUE)

glimpse(cleaned_crime_data)
glimpse(clean_outcome_data)


write_csv(cleaned_crime_data,"cleaned_crime_data.csv")
write_csv(clean_outcome_data,"cleaned_outcome_data.csv")

police_strength <- read_csv("Police_Force_Strength (1).csv",locale = locale(encoding = "latin1"))

glimpse(police_strength)

police_strength <- police_strength %>%
  janitor::clean_names()

glimpse(police_strength)

date_seq <- seq(ym("2013-05"), by = "1 month", length.out = nrow(police_strength))

police_strength <- police_strength %>%
  mutate(
    date = date_seq,
    year = year(date),
    total_officers = (police_officer_strength + police_staff_strength + pcso_strength),
    year_and_month = format_ISO8601(date,precision = "ym"),
    month = format(as.Date(date),"%B")
  ) %>% select(year,year_and_month,month,police_officer_strength,police_staff_strength,pcso_strength,total_officers)

glimpse(police_strength)

write_csv(police_strength,"cleaned_police_force_strange.csv")


depress_data <- read_csv("ADMP assessment Folder/ADMP assessment/File_7_-_All.csv")


clean_depress_data <-depress_data %>% clean_names()

clean_depress_data <- clean_depress_data %>%
  select(
    lsoa_code_2011,
    lsoa_name_2011,
    index_of_multiple_deprivation_imd_score,
    index_of_multiple_deprivation_imd_rank_where_1_is_most_deprived,
    index_of_multiple_deprivation_imd_decile_where_1_is_most_deprived_10_percent_of_lso_as,
    income_score_rate,
    employment_score_rate,
    education_skills_and_training_score,
    health_deprivation_and_disability_score,
    crime_score,
    barriers_to_housing_and_services_score,
    living_environment_score
  ) %>%
  rename(
    lsoa_code = lsoa_code_2011,
    lsoa_name = lsoa_name_2011,
    imd_score = index_of_multiple_deprivation_imd_score,
    imd_rank = index_of_multiple_deprivation_imd_rank_where_1_is_most_deprived,
    imd_decile = index_of_multiple_deprivation_imd_decile_where_1_is_most_deprived_10_percent_of_lso_as,
    income_score = income_score_rate,
    employment_score = employment_score_rate,
    education_score_rate = education_skills_and_training_score,
  )

clean_depress_data <- clean_depress_data %>%
  mutate(
    DeprivationLevel = case_when(
      imd_score <= 5 ~ "Very Low",
      imd_score <= 10 ~ "Low",
      imd_score <= 15 ~ "Medium",
      imd_score <= 25 ~ "High",
      TRUE ~ "Very High"
    )
  )


View(clean_depress_data)
View(depress_data)

write_csv(clean_depress_data,"clean_deprivation.csv")



stop_search <- read_csv("stop_and_search_2015_2025.csv")
View(stop_search)

clean_stop <-stop_search %>% clean_names()
View(clean_stop)

clean_stop_search <- clean_stop %>%
  mutate(
    year_and_month = format_ISO8601(date,precision = "ym"),
    month = month(date),
    month_name = month.name[month],
    year = year(date)
  ) %>% select(type,date,latitude,longitude,gender,
               age_range,self_defined_ethnicity,officer_defined_ethnicity,
               legislation,object_of_search,outcome,outcome_linked_to_object_of_search,
               removal_of_more_than_just_outer_clothing,year_and_month,month_name,year)

View(clean_stop_search)

write_csv(clean_stop_search,"clean_stop_and_search_data.csv")

join_crime_police_deprivation <- read_csv("join_crime_police_deprivation.csv")

clean_join_crime_police_deprivation <- join_crime_police_deprivation%>% clean_names()


clean_join_crime_police_deprivation <- clean_join_crime_police_deprivation %>%
  distinct(crime_id, .keep_all = TRUE)

count <- clean_join_crime_police_deprivation %>% count(outcome_type,sort = TRUE)

print(count,n=Inf)

solved <- c(
  "Suspect charged",
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
  "Offender given community sentence"
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

clean_join_crime_police_deprivation <- clean_join_crime_police_deprivation %>%
  mutate(case_status = case_when(
    outcome_type %in% solved ~ "Solved",
    outcome_type %in% unsolved ~ "Unsolved",
    is.na(outcome_type) ~ "Unknown",
    TRUE ~ "Other"
  ))

clean_join_crime_police_deprivation <- clean_join_crime_police_deprivation %>%
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
    pcso_strength = as.numeric(pcso_strength)
  )

clean_join_crime_police_deprivation <- clean_join_crime_police_deprivation %>%
  mutate(
    crime_type = as.factor(crime_type),
    deprivation_level = factor(deprivation_level, levels = c("Low", "Medium", "High"), ordered = TRUE),
    case_status = factor(case_status, levels = c("Solved", "Unsolved", "Unknown")),
    location = str_to_title(location)  
  )

clean_join_crime_police_deprivation <- clean_join_crime_police_deprivation %>%
  mutate(
    imd_score_scaled = scale(imd_score),
    income_score_scaled = scale(income_score)
  )

clean_join_crime_police_deprivation <- clean_join_crime_police_deprivation %>%
  mutate(across(where(is.character), ~na_if(., "NA")))

View(clean_join_crime_police_deprivation)

glimpse(clean_join_crime_police_deprivation)
summary(clean_join_crime_police_deprivation)

write_csv(clean_join_crime_police_deprivation,"clean_join_crime_police_deprivation.csv")


join_street_deprivation_police <- read_csv("join_street_deprivation_police.csv")

clean_join_street_deprivation_police <- join_street_deprivation_police %>% clean_names()

clean_join_street_deprivation_police <- clean_join_street_deprivation_police %>%
  distinct(crime_id, .keep_all = TRUE)

count_outcome <- clean_join_street_deprivation %>% count(last_outcome_category,sort = TRUE)

print(count_outcome,n=Inf)

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


clean_join_street_deprivation_police <- clean_join_street_deprivation_police %>%
  mutate(case_status = case_when(
    last_outcome_category %in% solved ~ "Solved",
    last_outcome_category %in% unsolved ~ "Unsolved",
    last_outcome_category %in% unknown ~ "Unknown",
    TRUE ~ "Other"
  ))


clean_join_street_deprivation_police <- clean_join_street_deprivation_police %>%
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

clean_join_street_deprivation <- clean_join_street_deprivation %>%
  mutate(
    crime_type = as.factor(crime_type),
    deprivation_level = factor(deprivation_level, levels = c("Low", "Medium", "High"), ordered = TRUE),
    case_status = factor(case_status, levels = c("Solved", "Unsolved", "Unknown")),
    location = str_to_title(location)  
  )



clean_join_street_deprivation_police <- clean_join_street_deprivation_police %>%
  rename(
    lsoa_name = lsoa_name_x,
    month = month_x,
    year = year_x
  )

clean_join_street_deprivation_police <- clean_join_street_deprivation_police %>%
  select(
    -lsoa_name_y,
    -year_y,
    -month_y,
    -context
  )

clean_join_street_deprivation_police <- clean_join_street_deprivation_police %>%
  mutate(across(where(is.character), ~na_if(., "NA")))

view(clean_join_street_deprivation_police)

write_csv(clean_join_street_deprivation_police,"clean_join_street_deprivation_police.csv")


summary(clean_join_street_deprivation_police)

count(clean_join_street_deprivation_police)

lapply(clean_join_street_deprivation_police, table)

count_lsoa_code <- clean_join_street_deprivation_police %>% count(lsoa_code,sort = TRUE)

print(count_lsoa_code,n=Inf)

count_lsoa_name <- clean_join_street_deprivation_police %>% count(lsoa_name,sort = TRUE)

print(count_lsoa_name,n=Inf)
