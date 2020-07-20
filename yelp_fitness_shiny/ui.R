shinyUI(dashboardPage(
    skin = "red",
    dashboardHeader(title = "Los Angeles Gyms"),
    dashboardSidebar(
        sidebarMenu(
            menuItem("Introduction",
                     tabName = "intro",
                     icon = icon("book")),
            menuItem(
                "Best & Worst Gyms",
                tabName = "best",
                icon = icon("trophy")
            ),
            menuItem(
                "Distribution of Ratings",
                tabName = "ratings",
                icon = icon("chart-area")
            ),
            menuItem(
                "Review Length Analysis",
                tabName = "length",
                icon = icon("pen")
            ),
            menuItem(
                "Sentiment Analysis",
                tabName = "sentiment",
                icon = icon("theater-masks")
            )
        )
    ),
    dashboardBody(
        tabItems(
            tabItem(tabName = "intro",
                    fluidRow(
                        box(
                            width = 10,
                            h2("Gym Yelp Reviews in Los Angeles"),
                            br(),
                            br(),
                            p("This exploratory data analysis examines over 27,000 yelp
                            reviews from Gyms in Los Angeles. The data was scraped from 
                              yelp business page with locations matching 'Los Angeles', 
                              'West Hollywood', 'Beverly Hills', 'Culver City', and 'Santa Monica'"
                            ),
                            br(),
                            p("We hope to gain the following insights:"),
                            tags$li("What gyms perform the best and worst?"),
                            tags$li("Do ratings differ by region? By category?"),
                            tags$li("Has review length changed over time? By rating?"),
                            tags$li("Has sentiment changed over time? What words contribute
                                    to ratings?")))),
            tabItem(tabName = "best",
                    fluidRow(
                        plotOutput("best"),
                        plotOutput("worst"),
                        box(h2("What are LA's Best and Worst Gyms?"),
                            br(),
                            br(),
                            p("For this analysis to be meaningul, gyms with less than 100
                            reviews were ommitted.")))),
            tabItem(tabName = "ratings",
                    fluidRow(plotOutput("yelp_ratings"),
                             plotOutput("yelp_ratings_by_region"),
                             plotOutput("yelp_ratings_by_category"),
                             box(
                                 width = 10,
                                 h2("How are gym reviews distributed?"),
                                 br(),
                                 p("The overall shape of the distribution is unexepcted. 
                                 We would have imagined an even or normal distribution of 
                                 1-5 stars; however, the majority of gym ratings in LA are skewed
                                 to the right. Either clients in LA have a favorable opinion of
                                 fitness facilities, regardless of rating, or poorly rated gyms don't survive
                                 long enough to have yelp reviews."),
                                 br(),
                                 h2("Gym Reviews by Region"),
                                 p("Los Angeles County is made up of over 99 neighborhoods. Some are
                                   more popular for their fitness scene. Here we represent the 
                                   neighborhoods with the largest number of gyms. As shown, the 
                                   vast majority of gyms are very favorably rated with very little
                                   rated beneath 4."),
                                 br(),
                                 h2("Gym Reviews by Category"),
                                 p("When we refine gym ratings by category, we see a 5 star rating
                                   represents at least ~72% of each category. Some modalities are
                                   more favorably rated than others.")))),
            tabItem(tabName = "length",
                    fluidRow(plotOutput("length_by_month"),
                             plotOutput("length_by_rating"),
                             box(
                                 width = 10,
                                 h2("What is the average yelp review length?"),
                                 br(),
                                 p("Yelp reviews for gyms average about 70-80 words per review 
                                   and this average has remained for at least the last decade.
                                   What’s going on with that mass of messy data from ~2005 to 2008? 
                                   Well, Yelp was founded around the end of 2004 and, at first glance 
                                   at least, the initial review length appears quite different from 
                                   the current trend and significantly more varied. However, there 
                                   were significantly fewer reviews starting out (obviously, since 
                                   the company wasn’t as well known) and it took Yelp many years to 
                                   stabilize to it’s current levels. Looking at the table below, 
                                   we don’t really start to see a substantial number of reviews until 2009."),
                                 br(),
                                 h2("What is the average yelp review length by rating?"),
                                 p("Good reviews tend to be significantly shorter and 5 star reviews are 
                                   the shortest of all by a good amount. Perhaps people like to vent when 
                                   they have a bad fitness experience, but when they have a good one they 
                                   are more succinct – ie “Great Workout!” could be a full review for a 
                                   5 star restaurant.")))),
            tabItem(tabName = "sentiment",
                    fluidRow(plotOutput("sentiment_over_time"),
                             plotOutput("length_vs_sentiment"),
                             plotOutput("word_contribution"),
                             box(
                                 width = 10,
                                 h2("Has the Average Sentiment of a Review Changed Over Time?"),
                                 br(),
                                 p("One fascinating area to explore is whether reviews have become more 
                                   positive or negative throughout the years. If we group the reviews 
                                   by month and rating, we can examine whether, perhaps, bad reviews have 
                                   gotten more extravagantly negative throughout the years. This is a pretty amazing insight. 
                                   It seems that negative reviews have gotten slightly more negative and positive reviews 
                                   have remained steady."),
                                 br(),
                                 h2("Is there a correlation between review length and sentiment?"),
                                 p("Short reviews seem to be more hyperbolic. The shorter the review the 
                                 more likely it will be scored with a very high or very low sentiment rating.
                                 But one question you should have when looking at this plot is ‘How come 1 star 
                                 and 5 star reviews both have so many high and low sentiment reviews?’ And that’s a 
                                 good point. Why are we seeing low sentiment 5 star reviews at all? This is an issue 
                                 with using basic sentiment analysis. ‘Holy shit. That’s all 
                                 I can say.’ is a 5 star review, but has a -4 sentiment score. There are several 
                                 reasons for this. The ‘afinn’ sentiment dataset is relatively small and many words 
                                 aren’t captured by it. This reduces the number of words that are scored,
                                 giving more weight to those words that are scored. One of the words that is 
                                 included is ‘shit’, which happens to receive a -4 score. Any human that 
                                 reads this review will recognize that ‘Holy shit’ is a good exclamation 
                                 in this context, but our naive sentiment scoring can’t pickup on that. 
                                 This sort of sentiment analysis will also mishandle negation of words – 
                                 ‘not like’ is obviously negative to us, but will be see as ‘like’ to the 
                                 sentiment analysis(at least in it’s present form).And similar things happen 
                                 in the negative reviews that receive high sentiment scores. ‘Would make for 
                                 an outstanding gym for pigs.’ is obviously a 
                                 negative review to humans, but all our sentiment analysis sees is ‘outstanding’. 
                                 There are a number of ways you could go about strengthening this sentiment 
                                 analysis–for instance, by using bi and trigrams to gather more context from 
                                 each review."),
                                 br(),
                                 h2("What words contribute the most to the sentiment of good and bad reviews?"),
                                 p("Lastly, we will look at the 
                                 number of times that a word occurs in a review and multiply that by that words 
                                 sentiment score. As you can see below, the contributions look quite different for
                                 each separate rating. 1 star reviews are overwhelmed by words such as unprofessional, worst 
                                 awful, and horrible, while 5 star reviews are dominated by positive words such as amazing
                                 and love. It’s important to point out that sentiment analysis by word 
                                 won’t catch certain intricacies of the English language. I have a feeling if I were
                                 to look at bigrams of review text, I’d see that what actually occurs most often 
                                 in 1 star reviews is ‘didn’t love’ or ‘don't care for’ rather than ‘love’ and 
                                 ‘amazing’. This sort of negation is missed by word level tokenization, but could 
                                 be easily captured by bigrams if you were so inclined.")
                                 )))
            
        ),
    )
))