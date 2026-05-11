class AddRouteIdToAddresses < ActiveRecord::Migration[7.1]
  def change
    add_column :addresses, :route_id, :uuid
    add_index :addresses, :route_id
  end
end
