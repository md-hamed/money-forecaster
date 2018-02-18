class Transaction < ApplicationRecord
  # Associations
  belongs_to :scenario

  # Validations
  validates :amount, :issued_on, :type, presence: true

  def signed_amount
    amount
  end
end
