class Vehicle < ApplicationRecord
  has_many :addresses
  validates :plate, :capacity, :model, presence: true
end
