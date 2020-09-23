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
  ylim(1.5, 5) +
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
nominee_data$ideology[nominee_data$nominee == 'Bade'] <- 0.344 # == Martha McSally in 2019
nominee_data$ideology[nominee_data$nominee == 'Barrett'] <- 0.474 # == Todd Young in 2017
nominee_data$ideology[nominee_data$nominee == 'Duncan'] <- mean(c(0.588, 0.457)) # == average of John Kennedy and Bill Cassidy in 2018
nominee_data$ideology[nominee_data$nominee == 'Eid'] <- 0.444 # == Cory Gardner in 2017
nominee_data$ideology[nominee_data$nominee == 'Grant'] <- mean(c(0.566, 0.402)) # == average of David Perdue and Johnny Isakson in 2018
nominee_data$ideology[nominee_data$nominee == 'Ho'] <- mean(c(0.817, 0.493)) # == average of Ted Cruz and John Cornyn in 2017
nominee_data$ideology[nominee_data$nominee == 'Lagoa'] <- mean(c(0.569, 0.514)) # == average of Marco Rubio and Rick Scott in 2019
nominee_data$ideology[nominee_data$nominee == 'Newsom'] <- mean(c(0.56, 0.429)) # == average of Luther Strange and Richard Shelby in 2017
nominee_data$ideology[nominee_data$nominee == 'Phipps'] <- 0.647 # == Pat Toomey in 2019
nominee_data$ideology[nominee_data$nominee == 'Rushing'] <- mean(c(0.428, 0.45)) # == average of Thom Tillis and Richard Burr in 2019
nominee_data$ideology[nominee_data$nominee == 'Ryan'] <- mean(c(0.409, 0.262)) # == average of George Allen and John Warner in 2006
nominee_data$ideology[nominee_data$nominee == 'Thapar'] <- mean(c(0.402, 0.878)) # == average of Mitch McConnell and Rand Paul in 2017
nominee_data$ideology[nominee_data$nominee == 'Willett'] <- mean(c(0.817, 0.493)) # == average of Ted Cruz and John Cornyn in 2017
# Stras's, Larsen's, and VanDyke's scores cannot be calculated because their home-state senators are all Democrats

nominee_data <- nominee_data %>% drop_na('ideology')
nominee_data <- arrange(nominee_data, desc(as.character(nominee_data$nominee)))
nominee_data$nominee <- factor(nominee_data$nominee, levels = nominee_data$nominee)

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
  annotate('text', x = 4.3, y = 16.5, size = 3, label = 'Thomas', color = '#CC79A7') +
  annotate('text', x = -0.4, y = 16.5, size = 3, label = 'Roberts', color = '#009E73') +
  annotate('text', x = -2.2, y = 16.5, size = 3, label = 'Ginsburg', color = '#D55E00') +
  annotate('text', x = 0.95, y = 11.5, size = 2.5, label = '2020') +
  annotate('text', x = -0.5, y = 11.5, size = 2.5, label = '2030') +
  labs(title = 'Maximum Possible Drift Over 10 Years') +
  labs(x = 'Ideology (Martin-Quinn units)', y = '', caption = '(left = liberal, right = conservative)') +
  xlim(-3, 5) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14))

