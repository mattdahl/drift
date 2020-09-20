# Libs
library(readr)
library(haven)
library(plyr)
library(dplyr)
library(ggplot2)
library(tibble)

WORKING_DIRECTORY = '/Users/mattdahl/Documents/nd/research/projects/drift/project/'

# Import data
consistency_scores <- data.frame(read_csv(paste(WORKING_DIRECTORY, 'data/consistency_scores.csv', sep = '')))
owens_wedeking_data <- data.frame(read_dta('data/owens_wedeking_data.dta'))

# Shape data
consistency_scores$nominee <- factor(consistency_scores$nominee, levels = consistency_scores$nominee)
consistency_scores <- consistency_scores[consistency_scores$nominee != 'Bade', ] # 5 docs
consistency_scores <- consistency_scores[consistency_scores$nominee != 'Muniz', ] # 3 docs
consistency_scores <- consistency_scores[consistency_scores$nominee != 'Rushing', ] # 4 docs
consistency_scores <- consistency_scores[consistency_scores$nominee != 'Vandyke', ] # 3 docs

## FIGURE 1: Line plot
##

ggplot(consistency_scores, aes(x = nominee, y = consistency_score, label = consistency_score)) + 
  geom_point(stat = 'identity', size = 3, color = "#009E73") +
  geom_hline(yintercept = owens_wedeking_data$corrected_cog_stand_dev[owens_wedeking_data$justice == 'Thomas'], color = '#D55E00', linetype='dashed') +
  geom_hline(yintercept = owens_wedeking_data$corrected_cog_stand_dev[owens_wedeking_data$justice == 'Ginsburg'], color = '#0072B2', linetype='dashed') +
  geom_hline(yintercept = owens_wedeking_data$corrected_cog_stand_dev[owens_wedeking_data$justice == 'Souter'], color = '#CC79A7', linetype='dashed') +
  geom_text(aes(x = 5.5, y = 2.35, label = 'Thomas'), color = '#D55E00') +
  geom_text(aes(x = 23.5, y = 3.9, label = 'Ginsburg'), color = '#0072B2') +
  geom_text(aes(x = 23.5, y = 4.85, label = 'Souter'), color = '#CC79A7') +
  labs(title = 'Trump\'s Potential Nominees\' Cognitive Consistencies') +
  labs(y = 'Cognitive Inconsistency', x = '', caption = '(higher score = more inconsistent/flexible)') +
  ylim(1, 5) +
  coord_flip() +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14))
