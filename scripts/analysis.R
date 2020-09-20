# Libs
library(readr)
library(haven)
library(plyr)
library(dplyr)
library(tools)

WORKING_DIRECTORY = '/Users/mattdahl/Documents/nd/research/projects/drift/project/'

# Data
owens_wedeking_data <- read_dta('data/owens_wedeking_data.dta')
liwc_result_files <- list.files(path = paste(WORKING_DIRECTORY, 'data/liwc_results/', sep = ''))
scores <- data.frame(nominee = character(), consistency_score = double())

for (liwc_result_file in liwc_result_files) {
  liwc_results <- read_csv(paste(WORKING_DIRECTORY, 'data/liwc_results/', liwc_result_file, sep = ''))
  
  # Select columns
  liwc_results <- select(liwc_results, 
    filename = Filename,
    six_letter = Sixltr,
    negation = negate,
    insight = insight,
    causation = cause,
    discrepancy = discrep,
    tentative = tentat,
    certainty = certain,
    inhibition = inhib,
    inclusiveness = incl,
    exclusiveness = excl
  )
  
  # Normalize (by taking the z-score) each dimension
  liwc_results[,-1] <- lapply(liwc_results[,-1], function (dimension) {
    scale(dimension, center = TRUE, scale = TRUE)
  })
  
  # Calculate complexity score for each document
  # (Composite formula taken from Owens and Wedeking's appendix)
  liwc_results$complexity_score <-
    liwc_results$six_letter - 
    liwc_results$causation -
    liwc_results$insight -
    liwc_results$discrepancy -
    liwc_results$inhibition -
    liwc_results$tentative -
    liwc_results$certainty -
    liwc_results$inclusiveness -
    liwc_results$exclusiveness -
    liwc_results$negation
  
  # Calculate the nominee's consistency score (standard deviation of all complexity scores)
  consistency_score <- round(as.numeric(sd(liwc_results$complexity_score)), digits = 3)
  
  # Append results to df
  scores <- rbind(scores, data.frame(
    nominee=toTitleCase(strsplit(liwc_result_file, split = '\\.')[[1]][1]),
    consistency_score=consistency_score
  ))
}

# Sort
scores <- arrange(scores, desc(scores$consistency_score))

# Save to disk
write.csv(scores, file = paste(WORKING_DIRECTORY, 'data/consistency_scores.csv', sep = ''), row.names = FALSE)
