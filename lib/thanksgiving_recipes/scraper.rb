class ThanksgivingRecipes::Scraper
    @@more_recipes = false
    def self.make_doc(url)
        Nokogiri::HTML(open(url))
    end
    def self.more_recipes
        @@more_recipes
    end
end
