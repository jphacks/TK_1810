json.merge! food_category.attributes.except(
  "updated_at",
  "created_at", 
)
