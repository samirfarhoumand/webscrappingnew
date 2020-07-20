library(plyr)
library(tidyverse)
library(readr)
library(lubridate)

setwd("~/Desktop/nyc/WebscrapingProject")
mydir = "raw_yelp_data"
myfiles = list.files(path=mydir, pattern="*.csv", full.names=TRUE)

yelp_data = ldply(myfiles, read_csv)

#check to see if every review for every gym is actually collected
check <- yelp_data %>%
  distinct(.) %>%
  unite(., col = unique_gym, gym, zipcode, sep ="-/-=") %>%
  mutate(., counter = 1) %>%
  group_by(., unique_gym) %>%
  summarise(., num_review = mean(num_review), review_count = sum(counter)) %>%
  mutate(., mismatch = ifelse(num_review != review_count, 1, 0)) %>%
  filter(., mismatch == 1)

#remove duplicate rows from multiple scans, remove duplicate rows from
#scans that yielded diffferent num_review results due to reviews 
#being posted /removed/filtered/unfiltered in between scrapes, 
#add back num_review, separate zip code from gym, change date to datetype, create
#a unique ID for each business

yelp_clean <- yelp_data %>%
  distinct(.) %>%
  unite(., col = unique_gym, gym, zipcode, sep ="-/-=") %>%
  select(., -num_review) %>%
  distinct(.) %>%
  mutate(., counter = 1) %>%
  group_by(., unique_gym) %>%
  mutate(., num_review = sum(counter)) %>%
  ungroup(.) %>%
  mutate(ID = group_indices(., .dots=c("unique_gym"))) %>%
  separate(., unique_gym, into = c("gym", "zipcode"), sep = "-/-=") %>%
  mutate(., reviewer_date = parse_date_time(reviewer_date, orders = "mdy"))%>%
  select(., -counter)

#check again
check_again <- yelp_clean %>%
  distinct(.) %>%
  unite(., col = unique_gym, gym, zipcode, sep ="-/-=") %>%
  mutate(., counter = 1) %>%
  group_by(., unique_gym) %>%
  summarise(., num_review = mean(num_review), review_count = sum(counter)) %>%
  mutate(., mismatch = ifelse(num_review != review_count, 1, 0)) %>%
  filter(., mismatch == 1)

number_of_gyms <- max(yelp_clean$ID)
summary(yelp_clean$rating)

write.csv(x = yelp_clean, file = "yelp_clean.csv", row.names = FALSE)







  