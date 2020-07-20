library(ggplot2)
library(tidyverse)
library(tidytext)
library(lubridate)
library(textdata)
library(RColorBrewer)
library(shinydashboard)
library(shiny)

yelp = read.csv("yelp_clean.csv")

# Select a color palette for the yelp reviews by gym category plot
colors = c(brewer.pal(9, 'PuBu')[c(5, 6, 7, 8, 9)])
t <- yelp %>%
  # Group by category and sum the # of unique restaurants of each category
  separate_rows(., category, sep = ",") %>%
  group_by(category)%>%
  mutate(t = n_distinct(ID))%>%
  # Need to ungroup to filter down to the top 3/4's of the restaurants
  ungroup()%>%
  filter(t >= quantile(t, .10))%>%
  # Now we regroup by category and star so we can calculate the total number
  # of reviews category X had for 1, 2, 3, etc stars
  # Looks as follows eg:
  # Gym: 1 star, 1234 reviews
  # Gym: 2 star, 1494 reviews
  # Gym: 3 star, 2003 reviews
  # Gym: 4 star, 2500 reviews
  # Gym: 5 star, 750 reviews
  group_by(category, rating)%>%
  summarise(count = n())%>%
  # redo grouping by just category
  ungroup()%>%
  group_by(category)%>%
  # grab the avg rating for each category NOTE this way sucks, I need a better way to do it
  mutate(working = rating*count, avg = sum(working)/sum(count))%>%
  # clean up df
  select(-working)%>%
  # sort by categorey and rating
  arrange(category, rating)
# Use the df created above to get a ranking of the categories by avg rating
# This is used to order the categories in the final plot
rankings <- t %>%
  distinct(category, .keep_all = TRUE)%>%
  select(category, avg)%>%
  arrange(desc(avg))
# Reorder categories by avg so that you get the cascade effect seen in the final plot
t$category <- factor(t$category, levels = rev(rankings$category))

#review length processing
all_tokens <- yelp%>%
  unnest_tokens(word, text)
# Count up how many times each word is used in each review
word_per_review <- all_tokens%>%
  unite(., col = review_id, gym, user_id, reviewer_date, sep ="-/-=") %>%
  count(review_id, word, sort = TRUE)
yelp_review_id <-unite(yelp, col = review_id, gym, user_id, reviewer_date, sep ="-/-=")
total_words_by_review <- word_per_review %>%
  group_by(review_id)%>%
  summarise(total = sum(n))%>%
  inner_join(yelp_review_id, by = 'review_id') %>%
  separate(., review_id, into = c("gym", "user_id", "reviewer_date"), sep = "-/-=") %>%
  mutate(., reviewer_date = parse_date_time(reviewer_date, orders = "ymd"))

#review length vs review sentiment
total_words_by_review_with_unique_id <- total_words_by_review %>%
  unite(., col = review_id, gym, user_id, reviewer_date, sep ="-/-=")

length_sentiment <- word_per_review%>%
  inner_join(get_sentiments('afinn'), by = 'word')%>%
  group_by(review_id)%>%
  summarise(sentiment = mean(value), words = n())%>%
  inner_join(total_words_by_review_with_unique_id, by = 'review_id')

#words with highest contribution to sentiment
p<- word_per_review%>%
  anti_join(stop_words)%>%
  inner_join(yelp_review_id, by = 'review_id')%>%
  select(-text)%>%
  inner_join(get_sentiments('afinn'), by = 'word')%>%
  group_by(rating, word)%>%
  summarise(occurences = n(), contribution = sum(value))%>%
  top_n(15, abs(contribution))%>%
  ungroup()%>%
  arrange(rating, contribution)%>%
  mutate(order = row_number())
