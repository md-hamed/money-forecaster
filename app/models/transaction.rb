class Transaction < ApplicationRecord
  monetize :amount_cents, with_model_currency: :currency
  
  # Associations
  belongs_to :scenario

  # Scopes
  scope :recurrent, -> { where.not(schedule: nil) }
  scope :non_recurrent, -> { where(schedule: nil) }
  scope :infinite, -> { recurrent.where(ending_on: nil) }

  # Validations
  validates :amount_cents, :issued_on, :type, presence: true
  validate :ending_date_is_after_issue_date

  # Callbacks
  before_save :update_schedule

  def recurrent?
    schedule.present?
  end

  def infinite_schedule?
    recurrent? && ending_on.nil?
  end

  def schedule
    IceCube::Schedule.from_yaml(self[:schedule]) if self[:schedule]
  end

  def self.recurrent_of_month(month, year)
    date = Date.new(year, month, 1)

    transactions = recurrent.where('issued_on <= ?', date)
                            .select { |t| t.schedule.occurs_on? date }
  end

  private

  def ending_date_is_after_issue_date
    if ending_on.present? && ending_on < issued_on
      errors.add :ending_on, "can't be before issued date"
    end
  end

  def update_schedule
    s = self.schedule
    if s.present?
      s.start_time = issued_on
      s.recurrence_rules.first.until(ending_on)
      self.schedule = s.to_yaml
    end
  end
end
