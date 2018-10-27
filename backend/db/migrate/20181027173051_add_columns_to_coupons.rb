class AddColumnsToCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :coupons, :comment, :string, null: false
    add_column :coupons, :tweet_url, :string, null: false
    add_reference :coupons, :food_category, foreign_key: true
  end
end
