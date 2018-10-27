class AddColumns < ActiveRecord::Migration[5.2]
  def change
    # add
    add_column :users, :twitter_desc,  :string
    add_column :users, :access_secret, :string
    add_column :users, :access_token,  :string
    add_column :users, :credentials,   :text
    add_column :users, :raw_info,      :text
    add_index  :users, [:provider, :uid], unique: true

    # change
    change_column :users, :provider,     :string, null: false
    change_column :users, :uid,          :string, null: false
    change_column :users, :twitter_name, :string, null: false
    change_column :users, :twitter_id,   :string, null: false
  
    # remove
    remove_column :users, :secret_token, :string
  end
end
