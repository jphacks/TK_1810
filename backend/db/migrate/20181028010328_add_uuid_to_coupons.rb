class AddUuidToCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :coupons, :uuid, :string, null:false
  end
end
