class CreateShops < ActiveRecord::Migration[5.2]
  def change
    create_table :shops do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.string :address, null: false
      t.float :latitude
      t.float :longitude
      t.integer :mean_coupon, null: false
      t.string :image_url

      t.timestamps
    end
  end
end
