class ThanksgivingRecipes::CLI
    attr_accessor :menu, :item, :recipe_list
    def initialize
        @item = ''
        @menu = []
        @recipe_list = []
    end
    
    def call
        until self.item == 'exit'
            until self.recipe_list.length > 0 || self.item == 'exit'
                choose_item
            end

            show_recipes = self.item != 'exit'
            while show_recipes
                print_recipes
                input = choose_recipe
                until input.between?(1,recipe_list.length) || input == -1
                    input = choose_recipe
                end
                break if input == -1

                current_recipe = self.recipe_list[input-1]
                FoodNetworkScraper.add_recipe_attributes(current_recipe)
       
                print `clear`
                print_recipe(current_recipe)
                add_recipe = add_recipe_to_menu?(current_recipe)
                add_recipe ? show_recipes = false : show_recipes = get_answer("Go back to #{self.item} recipes? y/n:")
            end
            if self.item != 'exit'
                print `clear`
                print_menu
                self.recipe_list.clear
            end
        end
        final_print
    end
    
    def retrieve_recipes(more = false)
        self.recipe_list.clear
        self.recipe_list = FoodNetworkScraper.get_recipes(self.item,more)
    end

    def print_recipes 
        recipe_list.each_with_index do |recipe,index|
            puts "--------------------------------------------------------------"
            puts "#{index+1}. #{recipe.title} by #{recipe.chef}"
        end
        puts ''
    end

    def print_recipe(recipe)
        puts "#{recipe.title} by #{recipe.chef}"
        puts "Link:#{recipe.link}"
        puts "Description: #{recipe.description}" if recipe.description.length > 0
        puts "Total Cook Time:#{recipe.total_cook_time} -- Active Cook Time:#{recipe.active_cook_time} -- Yields #{recipe.yield}"
        puts '--------------------------------Directions--------------------------------------'
        recipe.directions.each_with_index {|direction,index| puts "#{index+1}.#{direction}"}
        recipe.sub_recipes.each do |subrecipe|
            if subrecipe.directions.length > 0     
                print "\n"
                puts subrecipe.title.upcase
                subrecipe.directions.each_with_index {|direction,index| puts "#{index+1}.#{direction}"}
            end
        end
        puts '-------------------------------Ingredients--------------------------------------'
        recipe.ingredients.each {|ingredient| puts "#{ingredient.name}"}
        recipe.sub_recipes.each do |sub_recipe|
            print "\n"
            puts sub_recipe.title.upcase
            sub_recipe.ingredients.each {|ingredient| puts "#{ingredient.name}"}
        end
        print "\n"
    end

    def print_menu
        puts "Your Menu"
        self.menu.each_with_index do |recipe,index|
            puts "---------------------------#{index+1}---------------------------"
            puts "#{recipe.title} by #{recipe.chef}"
            puts "Link:#{recipe.link}"
        end
        puts "------------------------------------------------------"
    end
  
    def add_recipe_to_menu?(recipe)
        answer = get_answer('Add this recipe to your menu? y/n:')
        if answer
            print "\n"
            self.menu << recipe
            self.print_menu
        end
        answer
    end

    def get_answer(str)
        print str
        answer = gets.strip
        until ['y','yes','n','no'].include?(answer.downcase)
            puts "I dont understand that answer"
            print str
            answer = gets.strip
        end
        ['y','yes'].include?(answer.downcase)
    end

    def choose_item
        print "Type an item you would like to see recipes of or type exit to end:"
        self.item = gets.strip
        if self.item != 'exit'
            retrieve_recipes
            puts "No recipes found for that item" if self.recipe_list.length < 1
        end
    end

    def choose_recipe
        if FoodNetworkScraper.more_recipes
            puts 'More recipes available (Type "more" to see new recipes)'
        end
        print "Type the number of the recipe you would like to see more detail about or type -1 to search for a new item:"
        input = gets.strip
        if !input.to_i.between?(1,self.recipe_list.length) && input.to_i != -1 && input != 'more'
            puts "Invalid number, try again"
        elsif input == 'more' && !FoodNetworkScraper.more_recipes
            puts "No more recipes to show"
        elsif input == 'more' && FoodNetworkScraper.more_recipes
            retrieve_recipes(more = true)
            print `clear`
            print_recipes
        end
        input.to_i
    end
    
    def final_print
        print `clear`
        puts "Your Final Menu"
        print "\n"
        self.menu.each do |recipe|
            print_recipe(recipe)
            puts '*********************************************************************************************'
        end
    end

end