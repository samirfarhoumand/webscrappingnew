library(ggplot2)
library(tidyverse)
library(tidytext)
library(lubridate)
library(textdata)
library(RColorBrewer)

yelp = read.csv("yelp_clean.csv")

"
What questions do we want answered?
Highest and Lowest Rated Gyms in Los Angeles
-worst gyms CHECK 
-best gym CHECK

Distribution of Ratings
-distribution of yelp gym ratings CHECK
-distrubtion of yelp gym ratings by region (6) CHECK 
-distribution of yelp gym ratings by category CHECK second one


Analysis of Review Lengths
-average yelp review length by month CHECK
-review length by rating CHECK

Sentiment Analsysi
-average sentiment of yelp reviews? CHECK
-review length vs review sentiment? CHECK
-words with highest contribution towards sentiment CHECK
"""

#worst reviewed gym
yelp%>%
  filter(., num_review > 100) %>%
  group_by(., ID, gym) %>%
  summarise(., true_rating = mean(rating)) %>%
  arrange(., true_rating) %>%
  head(10) %>%
  ggplot(., aes(x=reorder(gym, -true_rating), y = true_rating)) +
  geom_bar(stat = "identity", fill = 'midnightblue', color = 'black', alpha = .7)+
  coord_flip()+
  labs(y = 'Average Rating',
     x = '', 
     title = 'Most Poorly Rated Gyms')
  

#best reviewed gym
yelp%>%
  filter(., num_review > 200) %>%
  group_by(., ID, gym) %>%
  summarise(., true_rating = mean(rating)) %>%
  arrange(., desc(true_rating)) %>%
  head(10) %>%
  ggplot(., aes(x=reorder(gym, true_rating), y = true_rating)) +
  geom_bar(stat = "identity", fill = 'midnightblue', color = 'black', alpha = .7)+
  coord_flip()+
  labs(y = 'Average Rating',
       x = '', 
       title = 'Most Highly Rated Gyms')

#number of gyms
yelp %>%
  distinct(ID) %>%
  count(.)

#distribution of yelp gym ratings
yelp %>%
  distinct(ID, .keep_all = TRUE) %>%
  ggplot(aes(x = avg_rating))+
  geom_bar(fill = 'midnightblue', color = 'black', alpha = .7)+
  labs(x = "Ratings",
       y = "# of Gyms",
       title = "Distribution of Yelp Gym Ratings")

#distribution of yelp gym ratings (different method)
yelp%>%
  distinct(ID, .keep_all = TRUE) %>%
  ggplot(., aes(rating, num_review)) +
  geom_jitter(aes(color = rating)) +
  scale_x_discrete("Stars") +
  scale_y_continuous("Number of reviews") +
  theme(legend.position = "none")  +
  labs(title = "Distribution of Yelp Gym Ratings")

#regions with the greatest number of reviews
yelp %>% 
  distinct(ID, .keep_all = TRUE)%>%
  group_by(., region) %>%
  tally() %>%
  filter(!is.na(region)) %>%
  arrange(desc(n)) %>%
  top_n(10)

#distribution of yelp ratings by region, input select the regions
yelp%>%
  # remove duplicate businesses (from the categories ennumeration)
  distinct(ID, .keep_all = TRUE)%>%
  filter((region %in% c('Hollywood', 'Beverly Grove', 'Hollywood Hills West', 'Sawtelle', 'Venice', 'Brentwood')))%>%
  # join my avg's df to be used for facet labeling
  group_by(region)%>%
  ggplot(aes(avg_rating))+
  geom_histogram(fill = 'midnightblue', color = 'black', alpha = .7, bins = 9)+
  facet_wrap(~region)+
  labs(x = 'Ratings',
       y = '# of Gyms',
       title = 'Distribution of Yelp Ratings by Region')

#average review length by month
# Tokenize review text
all_tokens <- yelp%>%
  unnest_tokens(word, text)
# Count up how many times each word is used in each review
word_per_review <- all_tokens%>%
  unite(., col = review_id, gym, user_id, reviewer_date, sep ="-/-=") %>%
  count(review_id, word, sort = TRUE)
# Save data and load it in to save time
saveRDS(word_per_review, file = 'review_words.rds')
word_per_review <- readRDS('review_words.rds')
# Count total # of words used in a review and then add the date back
yelp_review_id <-unite(yelp, col = review_id, gym, user_id, reviewer_date, sep ="-/-=")
total_words_by_review <- word_per_review%>%
  group_by(review_id)%>%
  summarise(total = sum(n))%>%
  inner_join(yelp_review_id, by = 'review_id') %>%
  separate(., review_id, into = c("gym", "user_id", "reviewer_date"), sep = "-/-=") %>%
  mutate(., reviewer_date = parse_date_time(reviewer_date, orders = "ymd"))
avg <- total_words_by_review%>%summarise(avg = mean(total))
# see how many words are in reviews over time
total_words_by_review%>%
  group_by(monthly = floor_date(reviewer_date, 'monthly'))%>%
  summarise(avg_len = mean(total))%>%
  ggplot(aes(monthly, avg_len))+
  geom_line()+
  stat_smooth(size = .3, color = 'red')+
  labs(x = '',
       y = '# of Words in Average Review',
       title = 'Average Yelp Review Length, by Month')

#review length by rating
avgs <- total_words_by_review%>%
  group_by(rating)%>%
  summarise(`Average word count` = round(mean(total),2))%>%
  rename(Stars = rating)

total_words_by_review%>%
  filter(reviewer_date >='2017-12-11')%>%
  group_by(weekly = floor_date(reviewer_date, 'weekly'), rating)%>%
  summarise(avg_len = mean(total))%>%
  ggplot(aes(weekly, avg_len))+
  geom_line()+
  stat_smooth(size = .5, se = FALSE, color = 'red')+
  facet_wrap(~rating, scales = 'free')+
  labs(x = '',
       y = '# of Words in Average Review',
       title = 'Average Yelp Review Length by Rating, by Week')

#average sentiment of yelp reivews over time
word_per_review%>%
  inner_join(get_sentiments('afinn'), by = 'word')%>%
  inner_join(yelp_review_id, by = 'review_id')%>%
  separate(., review_id, into = c("gym", "user_id", "reviewer_date"), sep = "-/-=") %>%
  mutate(., reviewer_date = parse_date_time(reviewer_date, orders = "ymd")) %>%
  filter(reviewer_date >='2015-01-01') %>%
  group_by(monthly = floor_date(reviewer_date, 'monthly'), rating)%>%
  summarise(sentiment = mean(value), words = n())%>%
  ggplot(aes(monthly, sentiment))+
  geom_line()+
  geom_smooth(color = 'red', size = .5)+
  facet_wrap(~rating, scales = 'free')+
  labs(x = '',
       y = 'Average Monthly Sentiment',
       title = 'Average Sentiment of Yelp Reviews 2010-2020, by Rating',
       subtitle = '(Data Grouped by Month)')


#review length vs review sentiment
total_words_by_review_with_unique_id <- total_words_by_review %>%
  unite(., col = review_id, gym, user_id, reviewer_date, sep ="-/-=")
  
length_sentiment <- word_per_review%>%
  inner_join(get_sentiments('afinn'), by = 'word')%>%
  group_by(review_id)%>%
  summarise(sentiment = mean(value), words = n())%>%
  inner_join(total_words_by_review_with_unique_id, by = 'review_id')

length_sentiment%>%
  ggplot(aes(total, sentiment))+
  geom_point(alpha = .1)+
  geom_smooth(color = 'red', se = FALSE, size = .5)+
  geom_hline(yintercept = 0, color = 'steelblue', linetype = 2)+
  facet_wrap(~rating)+
  labs(x = '# of Words in Review',
       y = 'Review Sentiment',
       title = 'Yelp Review Length vs. Review Sentiment Score',
       subtitle = 'Grouped by Rating')

#Words with the Highest Contribution Towards Sentiment
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

ggplot(p, aes(order, contribution, fill = contribution > 0))+
  geom_col(show.legend = FALSE)+
  facet_wrap(~rating, scales = 'free')+
  scale_x_continuous(
    breaks = p$order,
    labels = p$word,
    expand = c(0,0))+
  coord_flip()+
  labs(x = '',
       y = 'Contribution toward Sentiment',
       title = 'Words with the Highest Contribution Towards Sentiment')

#pull all the categories
categories <- yelp %>%
  distinct(., ID, .keep_all = TRUE) %>%
  separate_rows(., category, sep = ",") %>%
  group_by(., category) %>%
  count(.) %>%
  arrange(desc(n))

categories_top20 <- as.vector(head(categories$category, 20))
  
category_vector <- unique(categories$category)
top_category <- c("Gyms", "Trainers", "Boot Camps", "Pilates", "Yoga", "Dance Studios",
                  "Boxing", "Cycling Classes", "Barre Classes" )
  
#cdistribution of yelp ratings by category (input selectionize type)
yelp%>%
  distinct(ID, .keep_all = TRUE) %>%
  separate_rows(., category, sep = ",") %>%
  filter(., category %in% top_category)%>%
  group_by(category)%>%
  mutate(n = n())%>%
  ungroup()%>%
  group_by(category)%>%
  ggplot(aes(x = avg_rating))+
  geom_histogram(fill = 'midnightblue', color = 'black', alpha = .7, bins = 9)+
  facet_wrap(~category, scales = "free")+
  labs(x = 'Ratings',
       y = '# of Gyms',
       title = 'Distribution of Yelp Ratings for 6 \n most common gym categories')

#most favorably rated categories
best_categories <- yelp%>%
  separate_rows(., category, sep = ",") %>%
  filter(., category %in% categories_top20) %>%
  group_by(category)%>%
  summarise(., rating_by_category = mean(rating)) %>%
  arrange(desc(rating_by_category))

#distribution of yelp ratings by cateogires
# Select a color palette for the plot
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

# actual plotting
ggplot(t, aes(x = category, y = count, fill = as.factor(rating)))+
  geom_bar(stat = 'identity', position = 'fill', alpha = .8)+
  coord_flip()+
  # this percent labeling requires scales package
  theme(legend.title = element_blank(),
        legend.position="top",
        legend.direction="horizontal",
        legend.key.width=unit(0.75, "cm"),
        legend.key.height=unit(0.1, "cm"),
        legend.margin=margin(0, 0, -0.1, -2, "cm"))+
  scale_fill_manual(values=colors, labels = c("1 Star", "2 Star", "3 Star", "4 Star", "5 Star"))+
  labs(y = 'Proportion of Reviews',
       x = '', 
       title = 'Yelp Reviews by Gym Category')





  
