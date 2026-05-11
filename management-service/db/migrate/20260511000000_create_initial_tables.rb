class CreateInitialTables < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'pgcrypto'

    create_table :addresses, id: :uuid do |t|
      t.string :street
      t.string :number
      t.string :city
      t.string :state
      t.string :zip
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :status, default: 'pendente'
      t.uuid :vehicle_id

      t.timestamps
    end

    create_table :vehicles, id: :uuid do |t|
      t.string :plate
      t.integer :capacity
      t.string :model

      t.timestamps
    end

    create_table :drivers, id: :uuid do |t|
      t.string :name
      t.string :cpf

      t.timestamps
    end
  end
end
