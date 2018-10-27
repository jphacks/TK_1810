json.status @status
json.error_message @error
json.data do 
  json.food_categories do
    json.array! @food_categories, partial: 'food_categories/food_category', as: :food_category
  end
end
