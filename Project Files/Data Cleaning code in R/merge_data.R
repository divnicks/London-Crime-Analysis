library(dplyr)
library(readr)

folder_path <- "C:/Users/pathorn sriwatananuk/OneDrive - Sheffield Hallam University/Documents/ADMP assessment Folder/ADMP assessment/stop/all_data"

btp_files <- list.files(
  path = folder_path,
  pattern = "btp-street\\.csv$",
  full.names = TRUE
)

btp_data <- btp_files %>%
  lapply(read_csv) %>%
  bind_rows()

city_london_file <- list.files(
  path = folder_path,
  pattern = "city-of-london-street\\.csv$",
  full.names = TRUE
)

city_london_data <- city_london_file %>%
  lapply(read_csv) %>%
  bind_rows()


metropolitan_file <- list.files(
  path = folder_path,
  pattern = "metropolitan-street\\.csv$",
  full.names = TRUE
)

metropolitan_data <- metropolitan_file %>%
  lapply(read_csv) %>%
  bind_rows()


all_london_data <- bind_rows(btp_data, city_london_data, metropolitan_data)

View(all_london_data)

write_csv(all_london_data,"three_street_data.csv")
