class Scenario < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :transactions

  # Validations
  validates :title, presence: true
end
