# == Schema Information
#
# Table name: users
#
#  id            :bigint(8)        not null, primary key
#  provider      :string           not null
#  uid           :string           not null
#  twitter_name  :string           not null
#  twitter_id    :string           not null
#  image_url     :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  twitter_desc  :string
#  access_secret :string
#  access_token  :string
#  credentials   :text
#  raw_info      :text
#
class User < ApplicationRecord
  validates :uid, uniqueness: { scope: :provider }
  has_many :coupons, dependent: :destroy

  def self.find_or_create_from_auth(auth)
    # identifier
    provider = auth[:provider]
    uid      = auth[:uid]

    # user info
    twitter_id   = auth[:info][:nickname]
    twitter_name = auth[:info][:name]
    twitter_desc = auth[:info][:description]
    image_url    = auth[:info][:image]
    
    # token
    secret = auth[:credentials][:secret]
    token  = auth[:credentials][:token]

    # save other data as json
    credentials = auth[:credentials]
    raw_info    = auth[:extra][:raw_info]

    self.find_or_create_by(provider: provider, uid: uid) do |user|
      user.twitter_id    = twitter_id
      user.twitter_name  = twitter_name
      user.twitter_desc  = twitter_desc
      user.image_url     = image_url
      user.access_secret = secret
      user.access_token  = token

      user.credentials = credentials.to_json
      user.raw_info    = raw_info.to_json
    end
  end

  def impact
    n_followers = JSON.parse(self.raw_info)["followers_count"]
    if n_followers <= 1000
      return 0.1
    elsif n_followers <= 10000
      return 0.2
    else
      return 0.3
    end
  end
end
