class FoodCategoriesController < ApplicationController
  def index
    @food_categories = FoodCategory.all
  end
end
