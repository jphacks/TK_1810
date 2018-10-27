class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :twitter_name, null: false
      t.string :twitter_id, null: false, unique: true
      t.string :image_url
      t.string :secret_token

      t.timestamps
    end
  end
end
