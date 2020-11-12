class ThanksgivingRecipes::Ingredient
    def initialize(string)
        @name = string
    end
    attr_accessor :name, :recipe
end