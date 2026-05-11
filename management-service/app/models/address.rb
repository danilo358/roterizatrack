class Address < ApplicationRecord
  belongs_to :vehicle, optional: true
  validates :street, :number, :city, :state, :zip, presence: true
end
