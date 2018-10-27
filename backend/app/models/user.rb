# == Schema Information
#
# Table name: users
#
#  id            :bigint(8)        not null, primary key
#  provider      :string(255)      not null
#  uid           :string(255)      not null
#  twitter_name  :string(255)      not null
#  twitter_id    :string(255)      not null
#  image_url     :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  twitter_desc  :string(255)
#  access_secret :string(255)
#  access_token  :string(255)
#  credentials   :text(65535)
#  raw_info      :text(65535)
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
end
