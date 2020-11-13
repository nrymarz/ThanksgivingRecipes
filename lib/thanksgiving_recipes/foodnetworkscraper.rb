class FoodNetworkScraper < ThanksgivingRecipes::Scraper
    @@leftover_recipes = []
    @@page = ''
    def self.get_recipes(item, more=false)
        if more
            recipe_hashes = Array.new(@@leftover_recipes)
            page = @@page
        else
            url = build_url(item)
            recipe_docs = find_recipes(url,item)
            recipe_hashes = build_recipe_hashes(recipe_docs)
            page = get_next_page(url)
        end
        @@leftover_recipes.clear
        create_and_return_recipe_list(item,recipe_hashes,page)
    end

    def self.create_and_return_recipe_list(item,recipe_hashes,page)
        recipe_docs = find_recipes(page,item)
        while recipe_hashes.length < 10 && recipe_docs.length > 0
            more_recipe_hashes = build_recipe_hashes(recipe_docs)
            recipe_hashes.concat(more_recipe_hashes)
            page = get_next_page(page)
            recipe_docs = find_recipes(page,item)
        end
        while recipe_hashes.length > 10
            @@leftover_recipes << recipe_hashes.pop
        end
        @@page = page
        @@more_recipes = recipe_docs.length > 0 || @@leftover_recipes.length > 0
        recipe_hashes.collect {|recipe| recipe = ThanksgivingRecipes::Recipe.new(recipe)}
    end

    def self.delete_dupes(array_of_recipe_hashes)
        array_of_recipe_hashes.uniq!{|hash| hash[:title]}
    end

    def self.build_recipe_hashes(recipe_docs)
        recipe_hashes = recipe_docs.collect do |recipe|
            {
                title: recipe.css('.m-MediaBlock__a-HeadlineText').text,
                chef: recipe.css('.m-Info__a-AssetInfo').text.delete_prefix('Courtesy of '),
                link: 'https:'.concat(recipe.css('.m-MediaBlock__a-Headline a')[0]['href'])
            } 
        end
        delete_dupes(recipe_hashes)
        recipe_hashes
    end

    def self.find_recipes(url,item)
        doc = make_doc(url)
        recipe_list = doc.css('.o-RecipeResult')
        recipe_list.select do |recipe|
            title =  recipe.css('.m-MediaBlock__a-HeadlineText').text.downcase
            title.match(/#{item.downcase.chomp('s')}/)
        end
    end

    def self.get_recipe_info(url)
        doc = make_doc(url)
        ingredients = get_ingredients_list(doc)
        total_cook_time = doc.css('span.m-RecipeInfo__a-Description--Total')[0]
        active_cook_time = doc.css("ul.o-RecipeInfo__m-Time span.o-RecipeInfo__a-Description")[1]
        yeld = doc.css("ul.o-RecipeInfo__m-Yield span.o-RecipeInfo__a-Description")[0]
        sub_recipes = get_subrecipes(doc)
        directions = get_directions(doc)
        {
            description: doc.css('div.o-AssetDescription__a-Description').text.strip,
            ingredients: ingredients,
            total_cook_time: total_cook_time ? total_cook_time.text.strip : 'n/a',
            active_cook_time: active_cook_time ? active_cook_time.text.strip : 'n/a',
            yield: yeld ? yeld.text : 'n/a',
            sub_recipes: sub_recipes,
            directions: directions
        }
    end

    def self.add_recipe_attributes(recipe)
        attributes =  get_recipe_info(recipe.link)
        recipe.add_attributes(attributes)
    end

    def self.get_directions(doc,subrecipe=nil)
        if subrecipe
            subheaders = doc.css('h4.o-Method__a-SubHeadline')
            directions = subheaders.detect{|subhead| subhead.text.strip == subrecipe.text.strip}
        else
            directions = doc.css("ol")
        end
        if subrecipe && directions
            until directions.name == 'ol'
                directions = directions.next_element
            end
            directions.css('li.o-Method__m-Step').collect {|direction| direction.text.strip}
        elsif directions && !subrecipe
            directions[0].css('li.o-Method__m-Step').collect {|direction| direction.text.strip}
        else
            []
        end
    end

    def self.get_subrecipes(doc)
        sub_recipes = doc.css(".o-Ingredients__a-SubHeadline")
        sub_recipes.collect do |recipe|
            {
                title: recipe.text.strip.chomp(':'),
                ingredients: self.get_ingredients_list(doc,recipe),
                directions: self.get_directions(doc,recipe)
            }
        end
    end

    def self.get_ingredients_list(doc,subrecipe = nil)
        subrecipe ? element = subrecipe : element = doc.css('p.o-Ingredients__a-Ingredient')[0]
        ingredients = []
        if element
            while(element.next_element && element.next_element.attributes['class'].value == "o-Ingredients__a-Ingredient")
                ingredients << element.next_element.text.strip
                element = element.next_element
            end
        end
        ingredients
    end

    def self.build_url(item)
        item.gsub!('.',' ')
        term = item.gsub(' ','-')
        url = "https://www.foodnetwork.com/search/thanksgiving-#{term}-/CUSTOM_FACET:RECIPE_FACET"
    end

    def self.get_next_page(url)
        page = url.match(/\/p\/\d+/)
        if page
            page = page.to_s.delete_prefix('/p/').to_i 
            url.gsub(/\/p\/\d+/,"/p/#{page+1}")
        else
            url = url.split('/CUSTOM')
            url[0].concat('/p/2/CUSTOM')
            url.join
        end
    end
end