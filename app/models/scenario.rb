class Scenario < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :transactions, dependent: :destroy
  has_many :incomes
  has_many :expenses

  # Validations
  validates :title, presence: true
  validates :current_date, presence: true

  accepts_nested_attributes_for :transactions

  # Getters

  def income_of_month(month, year, percent: 0.0)
    total_recurrent_amount_of_month(:income, month, year, percent) + 
      total_non_recurrent_amount_of_month(:income, month, year)
  end

  def expenses_of_month(month, year, percent: 0.0)
    total_recurrent_amount_of_month(:expense, month, year, percent) + 
      total_non_recurrent_amount_of_month(:expense, month, year)
  end

  def revenue_of_month(month, year, income_percent: 0.0, expenses_percent: 0.0)
    income = income_of_month(month, year, percent: income_percent)
    expenses = expenses_of_month(month, year, percent: expenses_percent)
    income - expenses
  end

  # returns cumulative total for all months
  # if a month and year are provided; it returns cumulative
  # total till the provided date
  def cumulative_total(month = nil, year = nil, income_percent: 0.0, expenses_percent: 0.0)
    total_income = cumulative_recurrent_amount(:income, month, year, percent: income_percent) + cumulative_non_recurrent_amount(:income, month, year, percent: income_percent)
    total_expenses = cumulative_recurrent_amount(:expense, month, year, percent: expenses_percent) + cumulative_non_recurrent_amount(:expense, month, year, percent: expenses_percent)

    total_income - total_expenses
  end

  # alias bank_balance cumulative_total

  def first_forecasted_date
    current_date + 1.month
  end

  # Actions

  def add_income(amount, month, year, title = nil, ending_month: nil, ending_year: nil, payments_type: :one_time)
    add_transaction(:income, amount, month, year, title, ending_month, ending_year, payments_type)
  end

  def add_expense(amount, month, year, title = nil, ending_month: nil, ending_year: nil, payments_type: :one_time)
    add_transaction(:expense, amount, month, year, title, ending_month, ending_year, payments_type)
  end

  def duplicate
    scenario_params = self.attributes.except('id', 'created_at', 'updated_at')
    scenario_params['title'] += ' copy'
    duplicated_scenario = Scenario.new scenario_params
    transactions_params = transactions.map(&:attributes).map { |v| v.except('id', 'created_at', 'updated_at', 'scenario_id' ) }
    duplicated_scenario.transactions_attributes = transactions_params
    duplicated_scenario.save!
    duplicated_scenario
  end

  private

  def schedule_for_transaction(month, year, ending_month, ending_year, type)
    recurrent_transactions_types.include?(type) ? type : :one_time
    end_date = (ending_month.present? && ending_year.present?) ? Date.new(ending_year, ending_month) : nil

    case type
    when :monthly
      IceCube::Schedule.new(Date.new(year, month)) do |s|
        s.add_recurrence_rule(IceCube::Rule.monthly.day_of_month(1).until(end_date))
      end
    when :yearly
      IceCube::Schedule.new(Date.new(year, month)) do |s|
        s.add_recurrence_rule(IceCube::Rule.yearly.until(end_date))
      end
    end
  end

  def add_transaction(type, amount, month, year, title, ending_month, ending_year, payments_type)
    schedule = schedule_for_transaction(month, year, ending_month, ending_year, payments_type)

    model = type.to_s.classify.constantize
    issued_on = Date.new(year, month, 1)
    ending_on = Date.new(ending_year, ending_month, 1) if ending_year.present? && ending_month.present?
    money = Money.from_amount(amount)

    model.create(scenario: self,
                 amount: money,
                 title: title,
                 issued_on: issued_on,
                 ending_on: ending_on,
                 schedule: schedule.try(:to_yaml))
  end

  def recurrent_transactions_types
    [:one_time, :monthly, :yearly]
  end

  def total_recurrent_amount_of_month(type, month, year, percent)
    date = Date.new(year, month, 1)
    recurrent_transactions_of_month(type, month, year).sum do |t|
      if t.schedule.occurs_on? date
        forecasted_months = t.schedule.occurrences_between(first_forecasted_date, date)

        if forecasting?(month, year) && t.issued_on <= current_date
          # a transaction that needs to be raised
          raised_amount(t.amount, percent, forecasted_months.count)
        else
          t.amount
        end
      else
        0
      end
    end
  end

  def total_non_recurrent_amount_of_month(type, month, year)
    Money.new non_recurrent_transactions_of_month(type, month, year).sum(:amount_cents)
  end

  def recurrent_transactions_of_month(type, month, year)
    model = type.to_s.classify.constantize
    date = Date.new(year, month, 1)

    transactions = model.recurrent
                        .where(scenario: self)
                        .where('issued_on <= ?', date)

    finite_transactions = transactions.where('ending_on >= ?', date)
    infinite_transactions = transactions.infinite

    finite_transactions.or(infinite_transactions)
  end

  def non_recurrent_transactions_of_month(type, month, year)
    model = type.to_s.classify.constantize
    date = Date.new(year, month, 1)

    model.non_recurrent.non_recurrent
                       .where(scenario: self)
                       .where(issued_on: date)
  end

  def cumulative_recurrent_amount(type, month = nil, year = nil, percent: 0.0)
    if month.present? && year.present?
      date = Date.new(year, month, 1)
    else
      date = current_date
    end

    recurrent_transactions_of_month(type, date.month, date.year).sum do |t|
      non_forecasted_months = t.schedule.occurrences([current_date, date].min)
      forecasted_months = t.schedule.occurrences_between(first_forecasted_date, date)

      if forecasting?(date.month, date.year) && t.issued_on <= current_date
        # transaction should be raised
        total_forecasted_amount = forecasted_months.sum do |m|
          diff = t.schedule.occurrences_between(first_forecasted_date , m)
          raised_amount(t.amount, percent, diff.count)
        end

      else # don't raise
        total_forecasted_amount = t.amount * forecasted_months.count
      end

      non_forecasted_months.count * t.amount + total_forecasted_amount
    end
  end

  def cumulative_non_recurrent_amount(type, month = nil, year = nil, percent: 0.0)
    model = type.to_s.classify.constantize
    if month.present? && year.present?
      date = Date.new(year, month, 1)
    else
      date = current_date
    end

    Money.new(model.non_recurrent.where(scenario: self)
                   .where('issued_on <= ?', date)
                   .sum(:amount_cents))
  end

  def raised_amount(amount, percent, months_count)
    return amount if percent.zero?

    amount * ((1 + percent/100.0) ** months_count)
  end

  def forecasting?(month, year)
    Date.new(year, month, 1) > current_date
  end
end
