# == Schema Information
#
# Table name: food_categories
#
#  id         :bigint(8)        not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class FoodCategory < ApplicationRecord
  has_many :coupons
end
