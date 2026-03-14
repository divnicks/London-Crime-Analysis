library(ggplot2)
library(dplyr)
library(readr)

data <- read_csv("ADMP assessment Folder/ADMP assessment/clean_deprivation.csv")


ggplot(data, aes(x = "", y = imd_score)) +
  geom_boxplot(fill = "grey", color = "black") + 
  scale_y_continuous(breaks = seq(0, 90, 10))+
  labs(title = "Boxplot of IMD Scores", 
       x = "", 
       y = "IMD Score") +
  coord_flip() +
  theme_minimal() + 
  theme(
    panel.grid.minor = element_blank(), 
    panel.grid.major.x = element_blank(), 
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"), 
    axis.text = element_text(size = 10), 
    axis.title.y = element_text(size = 12)
  )

  