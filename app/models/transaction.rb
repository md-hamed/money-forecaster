class Transaction < ApplicationRecord
  monetize :amount_cents, with_model_currency: :currency
  
  # Associations
  belongs_to :scenario

  # Validations
  validates :amount_cents, :issued_on, :type, presence: true

  def signed_amount
    amount
  end
end
