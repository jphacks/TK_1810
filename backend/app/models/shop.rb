# == Schema Information
#
# Table name: shops
#
#  id          :bigint(8)        not null, primary key
#  name        :string(255)      not null
#  url         :string(255)      not null
#  address     :string(255)      not null
#  latitude    :float(24)
#  longitude   :float(24)
#  mean_coupon :integer          not null
#  image_url   :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Shop < ApplicationRecord
  geocoded_by :address
  after_validation :geocode

  has_many :coupons, dependent: :destroy
end
