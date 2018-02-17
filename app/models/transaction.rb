class Transaction < ApplicationRecord
  # Associations
  belongs_to :scenario

  # Validations
  validates :amount, :issued_on, presence: true
end
