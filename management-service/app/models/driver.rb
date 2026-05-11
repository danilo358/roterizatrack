class Driver < ApplicationRecord
  validates :name, :cpf, presence: true
end
