# == Schema Information
#
# Table name: shops
#
#  id          :bigint(8)        not null, primary key
#  name        :string           not null
#  url         :string           not null
#  address     :string           not null
#  latitude    :float
#  longitude   :float
#  mean_coupon :integer          not null
#  image_url   :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Shop < ApplicationRecord
  geocoded_by :address
  after_validation :geocode

  has_many :coupons, dependent: :destroy
end
