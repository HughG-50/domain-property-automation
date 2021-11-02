require 'nokogiri'
require 'httparty'
require 'byebug'
require 'csv'

class Job 
    attr_accessor :address, :land_area, :beds, :baths, :car_spaces, :sell_price, :date_sold

    def initialize(company, title, listing_url, location, category)
        @company = company
        @title = title
        @listing_url = listing_url
        @location = location
        @category = category
       
    end
       
end