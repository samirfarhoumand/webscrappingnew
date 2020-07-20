# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# https://doc.scrapy.org/en/latest/topics/items.html

import scrapy


class YelpItem(scrapy.Item):
    # define the fields for your item here like:
    # name = scrapy.Field()
    user_name = scrapy.Field()
    user_id = scrapy.Field()
    rating = scrapy.Field()
    text = scrapy.Field()
    reviewer_date = scrapy.Field()
    gym = scrapy.Field()
    address = scrapy.Field()
    zipcode = scrapy.Field()
    category = scrapy.Field()
    about = scrapy.Field()
    region = scrapy.Field()
    num_review = scrapy.Field()
    avg_rating = scrapy.Field()


