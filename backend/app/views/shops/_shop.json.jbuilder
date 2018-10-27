json.merge! shop.attributes.except(
  "updated_at",
  "created_at", 
)
