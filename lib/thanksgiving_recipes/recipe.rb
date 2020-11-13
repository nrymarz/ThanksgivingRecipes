class ThanksgivingRecipes::Recipe
    def initialize(attributes)
        attributes.each do |key,value|
            self.class.attr_accessor(key)
            self.send(("#{key}="),value)
        end
    end
    def add_attributes(attributes)
        attributes.each do |key,value|
            self.class.attr_accessor(key)
            self.send(("#{key}="),value)
        end
        self.ingredients = self.create_ingredients
        self.sub_recipes = create_sub_recipes(self.sub_recipes)
    end
    def create_ingredients
        self.ingredients.collect do |ingredient|
            ingredient = ThanksgivingRecipes::Ingredient.new(ingredient)
            ingredient.recipe = self
            ingredient
        end
    end
    def create_sub_recipes(sub_recipes)
        sub_recipes.collect do |sub_recipe|
            recipe = ThanksgivingRecipes::Recipe.new(sub_recipe)
            recipe.ingredients = recipe.create_ingredients if recipe.ingredients
            recipe
        end
    end
end