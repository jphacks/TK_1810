class CreateCoupons < ActiveRecord::Migration[5.2]
  def change
    create_table :coupons do |t|
      t.integer :amount, null: false
      t.datetime :available_from, null: false
      t.datetime :expired_at, null: false
      t.string :photo_url, null: false
      t.references :shop, null: false
      t.references :user, null: false
      t.float :insta_score, null: false
      t.boolean :is_used, null: false, default: false

      t.timestamps
    end
  end
end
