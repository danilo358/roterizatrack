class AddSequenceNumberToAddresses < ActiveRecord::Migration[7.1]
  def change
    add_column :addresses, :sequence_number, :integer
  end
end
