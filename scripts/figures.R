# Libs
library(readr)
library(haven)
library(tidyverse)
library(tibble)
library(ggplot2)
library(ggalt)

# Import data
nominee_data <- data.frame(read_csv('data/nominee_data.csv'))
owens_wedeking_data <- data.frame(read_dta('data/owens_wedeking_data.dta'))
jcs_data <- read_dta('data/jcs_data.dta')
mq_scores <- read_csv('~/Documents/nd/research/data/MartinQuinn_Scores_2019.csv')

# Shape data, dropping nominees with few documents
nominee_data$nominee <- factor(nominee_data$nominee, levels = nominee_data$nominee)
nominee_data <- nominee_data[nominee_data$nominee != 'Bade', ] # 5 docs
nominee_data <- nominee_data[nominee_data$nominee != 'Muniz', ] # 3 docs
nominee_data <- nominee_data[nominee_data$nominee != 'Rushing', ] # 4 docs
nominee_data <- nominee_data[nominee_data$nominee != 'Vandyke', ] # 3 docs

## FIGURE 1: Point estimates
##
ggplot(nominee_data, aes(x = nominee, y = consistency_score, label = consistency_score)) +
  geom_point(size = 3, color = '#0f85b8') +
  geom_hline(yintercept = owens_wedeking_data$corrected_cog_stand_dev[owens_wedeking_data$justice == 'Thomas'], color = '#D55E00', linetype='dashed') +
  geom_hline(yintercept = owens_wedeking_data$corrected_cog_stand_dev[owens_wedeking_data$justice == 'Souter'], color = '#CC79A7', linetype='dashed') +
  annotate('text', x = 5.5, y = 2.35, size = 3, label = 'Thomas', color = '#D55E00') +
  annotate('text', x = 23.5, y = 4.85, size = 3, label = 'Souter', color = '#CC79A7') +
  labs(title = 'Trump\'s Potential Nominees\' Cognitive Consistencies') +
  labs(y = 'Cognitive Inconsistency', x = '', caption = '(higher score = more inconsistent/flexible)') +
  ylim(1, 5) +
  coord_flip() +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14))


## FIGURE 2: Drift dumbbells
##
# Get available JCS scores
nominee_data$ideology<- NA
nominee_data$ideology[nominee_data$nominee == 'Colloton'] <- jcs_data$JCS2018[jcs_data$name == 'Colloton, Steven']
nominee_data$ideology[nominee_data$nominee == 'Gruender'] <- jcs_data$JCS2018[jcs_data$name == 'Gruender, Raymond']
nominee_data$ideology[nominee_data$nominee == 'Hardiman'] <- jcs_data$JCS2018[jcs_data$name == 'Hardiman, Thomas']
nominee_data$ideology[nominee_data$nominee == 'Kethledge'] <- jcs_data$JCS2018[jcs_data$name == 'Kethledge, Raymond']
nominee_data$ideology[nominee_data$nominee == 'Pryor'] <- jcs_data$JCS2018[jcs_data$name == 'Pryor, William']
nominee_data$ideology[nominee_data$nominee == 'Sykes'] <- jcs_data$JCS2018[jcs_data$name == 'Sykes, Diane']
nominee_data$ideology[nominee_data$nominee == 'Tymkovich'] <- jcs_data$JCS2018[jcs_data$name == 'Tymkovich, Timothy']
nominee_data <- nominee_data %>% drop_na('ideology')

# Transformation function, i.e., the inverse of the function given in Epstein et al. (2007)
mq_transformation <- function(jcs_score) {
  return((tan((pi * jcs_score) / 2) + 0.1736) / 0.461)
}

# Transform the JCS scores to MQ scores
nominee_data$ideology_mq <- mq_transformation(nominee_data$ideology)

# Drift prediction function, from OW
drift <- function(cognitive_inconsistency) {
  return(0.015841 * cognitive_inconsistency + 0.01433305)
}

# Calculate the ideology_hats for each nominee (assuming a time period of 10 years)
nominee_data$average_drift_per_term <- drift(nominee_data$consistency_score)
nominee_data$ideology_mq_hat <- nominee_data$ideology_mq - nominee_data$average_drift_per_term * 10

# Plot
ggplot(data = nominee_data, aes(x = ideology_mq, xend = ideology_mq_hat, y = nominee, group = nominee)) +
  geom_dumbbell(color = '#A3C4DC',
                colour_x = '#A3C4DC',
                size = 2,
                colour_xend = '#0E668B') +
  geom_vline(xintercept = mq_scores$post_mn[mq_scores$justiceName == 'CThomas' & mq_scores$term == 2019], color = '#CC79A7', linetype='dashed') +
  geom_vline(xintercept = mq_scores$post_mn[mq_scores$justiceName == 'JGRoberts' & mq_scores$term == 2019], color = '#009E73', linetype='dashed') +
  geom_vline(xintercept = mq_scores$post_mn[mq_scores$justiceName == 'RBGinsburg' & mq_scores$term == 2019], color = '#D55E00', linetype='dashed') +
  annotate('text', x = 4.3, y = 1.5, size = 3, label = 'Thomas', color = '#CC79A7') +
  annotate('text', x = -0.4, y = 1.5, size = 3, label = 'Roberts', color = '#009E73') +
  annotate('text', x = -2.2, y = 1.5, size = 3, label = 'Ginsburg', color = '#D55E00') +
  annotate('text', x = 1.9, y = 6.7, size = 2.5, label = '2020') +
  annotate('text', x = 0.75, y = 6.7, size = 2.5, label = '2030') +
  labs(title = 'Maximum Possible Drift Over 10 Years') +
  labs(x = 'Ideology (Martin-Quinn units)', y = '') +
  xlim(-3, 5) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14))

