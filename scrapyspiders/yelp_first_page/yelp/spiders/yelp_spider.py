from yelp.items import YelpItem
from scrapy import Spider, Request
import re 
import math


class YelpSpider(Spider):
    name = "yelp_spider"
    allowed_urls = ['https://www.yelp.com/']
    start_urls = ["https://www.yelp.com/search?find_desc=Gyms&find_loc=Santa%20Monica%2C%20CA&sortby=review_count&start=0"]

    def parse(self, response):
    # Find the total number of gyms in the result so that we can decide how many urls to scrape next
        num_gyms = response.xpath('//div[@class="lemon--div__373c0__1mboc border-color--default__373c0__3-ifU text-align--center__373c0__2n2yQ"]//span/text()').extract_first()
        groups = re.search("1 of (\d+)", num_gyms)
        items_per_page, total_items = 10, int(groups.group(1))
        num_pages = math.ceil(total_items/items_per_page)

    # List comprehension to construct all the urls
        result_urls = [f"https://www.yelp.com/search?find_desc=Gyms&find_loc=Santa%20Monica%2C%20CA&sortby=review_count&start={i*10}" for i in range(50, 100)]

        #print("="*55)
        #print(f"Number of URLS:",len(result_urls))
        #print(result_urls)
        #print("="*55)

    # Yield the requests to different search result urls, 
    # using parse_result_page function to parse the response.

        for url in result_urls:
            yield Request(url=url, callback= self.parse_results_page)

    def parse_results_page(self, response):
        # This funntion parses the search result page.
        
        # We are looking for url of each business page.
        gym_urls = list(filter(lambda x: x.startswith("/biz"),response.xpath('//span[@class="lemon--span__373c0__3997G text__373c0__2Kxyz text-color--black-regular__373c0__2vGEn text-align--left__373c0__2XGa- text-weight--bold__373c0__1elNz text-size--inherit__373c0__2fB3p"]//a/@href').extract()))
        gym_urls = ["https://www.yelp.com" + url for url in gym_urls]
        gym_urls = [url.partition("?")[0] for url in gym_urls]

        print("="*55)
        print(len(gym_urls))
        print("="*55)

        # Yield the requests to the product pages, 
        # using parse_detail_page function to parse the response.
        
        for url in gym_urls:
            yield Request(url = url, callback=self.parse_gym_reviews_page)

    def parse_gym_reviews_page(self, response):
        reviews = response.xpath('//li [@class="lemon--li__373c0__1r9wz margin-b3__373c0__q1DuY padding-b3__373c0__342DA border--bottom__373c0__3qNtD border-color--default__373c0__3-ifU"]')
        

        gym = response.xpath('//h1[@class="lemon--h1__373c0__2ZHSL heading--h1__373c0__dvYgw undefined heading--inline__373c0__10ozy"]/text()').extract_first()
        address = response.xpath('//span [@class="lemon--span__373c0__3997G raw__373c0__3rcx7"]/text()').extract_first()
        zipcode = re.findall(r'9\d{4}',",".join(response.xpath('//span [@class="lemon--span__373c0__3997G raw__373c0__3rcx7"]/text()').extract()))[0]
        category = re.findall(r'(\w+\s?\w+)', ",".join(response.xpath('//span [@class="lemon--span__373c0__3997G display--inline__373c0__3JqBP margin-r1__373c0__zyKmV border-color--default__373c0__3-ifU"]//text()').extract()))
        
        try:
            num_review = int(re.search(r'(\d*\.?\d*)', response.xpath('//p [@class="lemon--p__373c0__3Qnnj text__373c0__2Kxyz text-color--mid__373c0__jCeOG text-align--left__373c0__2XGa- text-size--large__373c0__3t60B"]/text()').extract_first()).group(0))  
        except:
            num_review = 0

        about = response.xpath('//div [@class="lemon--div__373c0__1mboc margin-b1__373c0__1khoT border-color--default__373c0__3-ifU"]/p/span//text()').extract_first()
        region = response.xpath('//div [@class="lemon--div__373c0__1mboc pseudoIsland__373c0__Fak5q"]//p [@class="lemon--p__373c0__3Qnnj text__373c0__2Kxyz text-color--normal__373c0__3xep9 text-align--left__373c0__2XGa-"]/text()').extract_first()
        avg_rating = float(response.xpath('//span [@class="lemon--span__373c0__3997G display--inline__373c0__3JqBP border-color--default__373c0__3-ifU"]/div/@aria-label').extract_first().split()[0])
        
        for review in reviews:
            user_name = review.xpath('.//div [@class="lemon--div__373c0__1mboc border-color--default__373c0__3-ifU"]//a [@class="lemon--a__373c0__IEZFH link__373c0__1G70M link-color--inherit__373c0__3dzpk link-size--inherit__373c0__1VFlE"]/text()').extract_first()
            user_id = review.xpath('.//div [@class="lemon--div__373c0__1mboc border-color--default__373c0__3-ifU"]//a [@class="lemon--a__373c0__IEZFH link__373c0__1G70M link-color--inherit__373c0__3dzpk link-size--inherit__373c0__1VFlE"]/@href').extract_first().partition("=")[2]
            rating = int(review.xpath('.//div [@class="lemon--div__373c0__1mboc arrange-unit__373c0__o3tjT arrange-unit-grid-column--8__373c0__2dUx_ border-color--default__373c0__3-ifU"]//div/@aria-label').extract_first().split()[0])
            text = review.xpath('.//div [@class ="lemon--div__373c0__1mboc arrange-unit__373c0__o3tjT arrange-unit-grid-column--8__373c0__2dUx_ border-color--default__373c0__3-ifU"]//p [@class= "lemon--p__373c0__3Qnnj text__373c0__2Kxyz comment__373c0__3EKjH text-color--normal__373c0__3xep9 text-align--left__373c0__2XGa-"]/span [@class="lemon--span__373c0__3997G raw__373c0__3rKqk"]/text()').extract_first()
            reviewer_date = review.xpath('.//span [@class="lemon--span__373c0__3997G text__373c0__2Kxyz text-color--mid__373c0__jCeOG text-align--left__373c0__2XGa-"]/text()').extract_first()

            
            item = YelpItem()
            item["gym"] = gym
            item["zipcode"] = zipcode
            item["address"] = address
            item["category"] = category
            item["about"] = about
            item["region"] = region
            item["num_review"] = num_review
            item["avg_rating"] = avg_rating
            item["user_name"] = user_name
            item["user_id"] = user_id
            item["rating"] = rating
            item["text"] = text
            item["reviewer_date"] = reviewer_date
            yield item 
            


