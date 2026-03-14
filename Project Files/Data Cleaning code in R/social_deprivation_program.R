library(ggplot2)
library(dplyr)
library(readr)

data <- read_csv("ADMP assessment Folder/ADMP assessment/clean_deprivation.csv")

ggplot(data, aes(x = imd_score)) +
  geom_histogram(binwidth = 2, fill = "grey", color = "white") +
  scale_x_continuous(breaks = seq(0, 90, 10)) + 
  scale_y_continuous(breaks = seq(0, 4000, 1000)) + 
  labs(title = "Distribution of IMD Scores", 
       x = "", 
       y = "Frequency") + 
  theme_minimal() + 
  theme(panel.grid.minor = element_blank(), 
        panel.grid.major.x = element_blank(), 
        plot.title = element_text(hjust = 0.5, size = 14, face = "bold"), 
        axis.text = element_text(size = 10), 
        axis.title.y = element_text(size = 12)) 
