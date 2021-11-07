require 'nokogiri'
require 'httparty'
require 'byebug'
require 'csv'
require 'json'
require 'logger'
require 'selenium-webdriver'

class Job 
  attr_accessor :address, :land_area, :beds, :baths, :car_spaces, :sell_price, :date_sold, :listing_link

  def initialize(address, land_area, beds, baths, car_spaces, sell_price, date_sold, listing_link)
    @address = address
    @land_area = land_area
    @beds = beds
    @baths = baths
    @car_spaces = car_spaces
    @sell_price = sell_price
    @date_sold = date_sold
    @listing_link = listing_link
  end
       
end

def get_date_from_text(input_str)
  return input_str.match(/[0-9]{2}[ ]{1}[a-zA-Z]{3}[ ]{1}[0-9]{4}/)[0]
end

def text_includes_date(input_str)
  return /[0-9]{2}[ ]{1}[a-zA-Z]{3}[ ]{1}[0-9]{4}/.match?(input_str)
end

def convert_price_text_to_number(input_str)
  return input_str.gsub(/\D/,'').to_i
end

# Initialize logger
logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

def domain_sold_listings_scrape_page(driver, logger, target_suburb_url)
  driver.navigate.to target_suburb_url
  wait = Selenium::WebDriver::Wait.new(timeout: 5)

  logger.info("Navigated to Domain: #{target_suburb_url}")

  # Loop through the li elements - results should be around 20-21ish per page, start with li[1] or li[2]
  for listing_num in 1..2
    begin
      # Date sold - will be either on div2, div3 - get the text content
      date_sold_element = driver.find_element(xpath: "//*[@id='skip-link-content']/div[1]/div[2]/ul/li[#{listing_num}]/div/div[1]/div[2]")
      if(!text_includes_date(date_sold_element.text)) 
        date_sold_element = driver.find_element(xpath: "//*[@id='skip-link-content']/div[1]/div[2]/ul/li[#{listing_num}]/div/div[1]/div[3]")
      end
      date_sold = get_date_from_text(date_sold_element.text)
      logger.info("Date sold: #{date_sold}")

      # Address line 1
      address_line_1_element = driver.find_element(xpath: "//*[@id='skip-link-content']/div[1]/div[2]/ul/li[#{listing_num}]/div/div[2]/div/a/h2/span[1]")
      address_line_1 = address_line_1_element.text

      # Address line 2
      begin
        suburb_element = driver.find_element(xpath: "//*[@id='skip-link-content']/div[1]/div[2]/ul/li[#{listing_num}]/div/div[2]/div/a/h2/span[2]/span[1]")
        state_element = driver.find_element(xpath: "//*[@id='skip-link-content']/div[1]/div[2]/ul/li[#{listing_num}]/div/div[2]/div/a/h2/span[2]/span[2]")
        postcode_element = driver.find_element(xpath: "//*[@id='skip-link-content']/div[1]/div[2]/ul/li[#{listing_num}]/div/div[2]/div/a/h2/span[2]/span[3]")
        address_line_2 = "#{suburb_element.text} #{state_element.text} #{postcode_element.text}"
      rescue 
      end

      address = address_line_1 + address_line_2
      logger.info("Address: #{address}")

      # Beds
      beds_element = driver.find_element(xpath: "//*[@id='skip-link-content']/div[1]/div[2]/ul/li[#{listing_num}]/div/div[2]/div/div[2]/div[1]/div/span[1]/span")
      beds = beds_element.text.to_i
      logger.info("Beds: #{beds}")

      # Baths
      baths_element = driver.find_element(xpath: "//*[@id='skip-link-content']/div[1]/div[2]/ul/li[#{listing_num}]/div/div[2]/div/div[2]/div[1]/div/span[2]/span")
      baths = baths_element.text.to_i
      logger.info("Baths: #{baths}")

      # Car spaces
      cars_element = driver.find_element(xpath: "//*[@id='skip-link-content']/div[1]/div[2]/ul/li[#{listing_num}]/div/div[2]/div/div[2]/div[1]/div/span[3]/span")
      cars = cars_element.text.to_i
      logger.info("Cars: #{cars}")

      # Land Area
      land_area_element = driver.find_element(xpath: "//*[@id='skip-link-content']/div[1]/div[2]/ul/li[#{listing_num}]/div/div[2]/div/div[2]/div[1]/div/span[4]/span")
      land_area = land_area_element.text
      logger.info("Land area: #{land_area}")

      # Sold Price
      sold_price_element = driver.find_element(xpath: "//*[@id='skip-link-content']/div[1]/div[2]/ul/li[#{listing_num}]/div/div[2]/div/div[1]/p")
      sold_price = sold_price_element.text
      sold_price_number = convert_price_text_to_number(sold_price)
      logger.info("Sold price: #{sold_price}")
      logger.info(sold_price_number)
    rescue
    end
  end
end

def scrape_pages(driver, logger, target_url)
  for page_count in 1..5
    domain_sold_listings_scrape_page(driver, logger, "#{target_url}&page=#{page_count}")
  end
end

# Listing link - may need to use search api to get the listing link - no good way to target pseudo class which inserts link
# listing_link_element = driver.find_element(xpath: "/*[@id='skip-link-content']/div[1]/div[2]/ul/li[#{listing_num}]/div/div[2]/div/a")
# listing_link = listing_link_element.attribute("href")

# Initialize Selenium
# options = Selenium::WebDriver::Chrome::Options.new(args: ['headless'])
# driver = Selenium::WebDriver.for(:chrome, options: options)

# Run scraper
options = Selenium::WebDriver::Firefox::Options.new
options.headless!
driver = Selenium::WebDriver.for :firefox, options: options
driver = Selenium::WebDriver.for :firefox
driver.manage.timeouts.page_load = 300

scrape_pages(driver, logger, "https://www.domain.com.au/sold-listings/crestmead-qld-4132/?excludepricewithheld=1")

driver.quit