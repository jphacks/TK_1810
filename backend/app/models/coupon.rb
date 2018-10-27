# == Schema Information
#
# Table name: coupons
#
#  id               :bigint(8)        not null, primary key
#  amount           :integer          not null
#  available_from   :datetime         not null
#  expired_at       :datetime         not null
#  photo_url        :string           not null
#  shop_id          :bigint(8)        not null
#  user_id          :bigint(8)        not null
#  insta_score      :float            not null
#  is_used          :boolean          default(FALSE), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  comment          :string           not null
#  tweet_url        :string           not null
#  food_category_id :bigint(8)
#

class Coupon < ApplicationRecord
  belongs_to :user
  belongs_to :shop
  belongs_to :food_category
  
  def self.unused
    where(is_used: false)
  end
  
  def self.not_expired
    now = Time.current
    where("expired_at > ?", now)
  end

  def status
    now = Time.current
    if is_used
        return "使用済み"
    elsif now < available_from
        return "まだ使えません"
    elsif now > expired_at
        return "有効期限切れ"
    else
        return "使用できます"
    end
  end
end
