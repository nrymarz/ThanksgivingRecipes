class ThanksgivingRecipes::Scraper
    def self.make_doc(url)
        Nokogiri::HTML(open(url))
    end
end
