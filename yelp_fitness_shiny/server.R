shinyServer(function(input, output) {
    
    output$worst <- renderPlot({
        yelp%>%
            filter(., num_review > 25) %>%
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
        
    })
    
    output$best <- renderPlot({
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
        
    })
    
    output$yelp_ratings <- renderPlot({
        yelp%>%
            distinct(ID, .keep_all = TRUE) %>%
            ggplot(aes(x = avg_rating))+
            geom_bar(fill = 'midnightblue', color = 'black', alpha = .7)+
            labs(x = "Ratings",
                 y = "# of Gyms",
                 title = "Distribution of Yelp Gym Ratings")
        
    })
    
    output$yelp_ratings_by_region <- renderPlot({
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
        
    })

    output$yelp_ratings_by_category <- renderPlot({
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
    })
    
    
    output$length_by_month <- renderPlot({
        total_words_by_review%>%
            group_by(monthly = floor_date(reviewer_date, 'monthly'))%>%
            summarise(avg_len = mean(total))%>%
            ggplot(aes(monthly, avg_len))+
            geom_line()+
            stat_smooth(size = .3, color = 'red')+
            labs(x = '',
                 y = '# of Words in Average Review',
                 title = 'Average Yelp Review Length, by Month')
    })

    output$length_by_rating <- renderPlot({
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
    })
    
    output$length_vs_sentiment <- renderPlot({
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
    })
    
    output$word_contribution <- renderPlot({
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
    })

    output$sentiment_over_time <- renderPlot({
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
    })
    
})