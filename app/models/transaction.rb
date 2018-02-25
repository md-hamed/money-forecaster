class Transaction < ApplicationRecord
  monetize :amount_cents, with_model_currency: :currency
  
  # Associations
  belongs_to :scenario

  # Scopes
  scope :recurrent, -> { where.not(ending_on: nil) }
  scope :non_recurrent, -> { where(ending_on: nil) }

  # Validations
  validates :amount_cents, :issued_on, :type, presence: true
  validate :ending_date_is_after_issue_date

  def signed_amount
    amount
  end

  def recurrant?
    ending_on.present? && ending_on > issued_on
  end

  private

  def ending_date_is_after_issue_date
    if ending_on.present? && ending_on < issued_on
      errors.add :ending_on, "can't be before issued date"
    end
  end
end
