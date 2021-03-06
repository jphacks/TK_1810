# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# shops
json = ActiveSupport::JSON.decode(File.read('db/seeds/shops.json'))
json.each do |data|
  #Shop.create!(*d, without_protection: true)
  Shop.create!(data)
end

# food category
json = ActiveSupport::JSON.decode(File.read('db/seeds/food_category.json'))
json.each do |data|
  FoodCategory.create!(data)
end
