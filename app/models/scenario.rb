class Scenario < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :transactions, dependent: :destroy
  has_many :incomes
  has_many :expenses

  # Validations
  validates :title, presence: true

  accepts_nested_attributes_for :transactions

  # Getters

  def income_of_month(month, year, percent: 0.0)
    amount = total_recurrent_amount_of_month(:income, month, year) + total_non_recurrent_amount_of_month(:income, month, year)
    forecasting?(month, year) ? raised_amount(amount, percent, month, year) : amount
  end

  def expenses_of_month(month, year, percent: 0.0)
    amount = total_recurrent_amount_of_month(:expense, month, year) + total_non_recurrent_amount_of_month(:expense, month, year)
    forecasting?(month, year) ? raised_amount(amount, percent, month, year) : amount
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

  alias bank_balance cumulative_total

  # Actions

  def add_income(amount, month, year, title = nil, ending_month: nil, ending_year: nil)
    add_transaction(:income, amount, month, year, title, 
                    ending_month: ending_month, ending_year: ending_year)
  end

  def add_expense(amount, month, year, title = nil, ending_month: nil, ending_year: nil)
    add_transaction(:expense, amount, month, year, title, 
                    ending_month: ending_month, ending_year: ending_year)
  end

  def add_transaction(type, amount, month, year, title = nil, ending_month: nil, ending_year: nil)
    date = Date.new(year, month, 1)
    model = type.to_s.classify.constantize
    money = Money.from_amount(amount)

    if ending_month.present? && ending_year.present?
      ending_date = Date.new(ending_year, ending_month)
    end

    model.create(scenario: self,
                 amount: money,
                 ending_on: ending_date,
                 issued_on: date,
                 title: title)
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

  def last_transaction_date
    @last_transaction_date ||= transactions.maximum(:issued_on)
  end
  
  private

  def total_recurrent_amount_of_month(type, month, year)
    Money.new recurrent_transactions_of_month(type, month, year).sum(:amount_cents)
  end

  def total_non_recurrent_amount_of_month(type, month, year)
    Money.new non_recurrent_transactions_of_month(type, month, year).sum(:amount_cents)
  end

  def recurrent_transactions_of_month(type, month, year)
    model = type.to_s.classify.constantize
    date = Date.new(year, month, 1)

    model.recurrent
         .where(scenario: self)
         .where('ending_on >= ?', date)
         .where('issued_on <= ?', date)
  end

  def non_recurrent_transactions_of_month(type, month, year)
    model = type.to_s.classify.constantize
    date = Date.new(year, month, 1)

    model.non_recurrent.where(scenario: self)
                       .where(issued_on: date)
  end

  def cumulative_recurrent_amount(type, month = nil, year = nil, percent: 0.0, include_known_months: true)
    if month.present? && year.present?
      date = Date.new(year, month, 1)
    else
      date = last_transaction_date
    end

    first_forecasted_month = last_transaction_date + 1.month
    recurrent_transactions_of_month(type, date.month, date.year).sum do |transaction|
      last_date_with_transactions_available = forecasting?(date.month, date.year) ? last_transaction_date : date

      forecasted_months_count = months_difference(date, last_date_with_transactions_available)
      non_forecasted_months_count = months_difference(last_date_with_transactions_available, transaction.issued_on) + 1

      total_forecasted_amount = 0
      forecasted_months_count.times do |i|
        total_forecasted_amount += raised_amount(transaction.amount, percent, (first_forecasted_month + i.months).month, (first_forecasted_month + i.months).year)
      end

      include_known_months ? non_forecasted_months_count * transaction.amount + total_forecasted_amount : Money.new(total_forecasted_amount)
    end
  end

  def cumulative_non_recurrent_amount(type, month = nil, year = nil, percent: 0.0)
    model = type.to_s.classify.constantize
    if month.present? && year.present?
      date = Date.new(year, month, 1)
    else
      date = last_transaction_date
    end

    Money.new(model.non_recurrent.where(scenario: self)
                   .where('issued_on <= ?', date)
                   .sum(:amount_cents))
  end

  def months_difference(current_date, previous_date)
    (current_date.year * 12 + current_date.month) - (previous_date.year * 12 + previous_date.month)
  end

  def raised_amount(amount, percent, month, year)
    return amount if percent.zero?

    diff = months_difference(Date.new(year, month, 1), last_transaction_date)
    amount * ((1 + percent/100.0) ** diff)
  end

  def forecasting?(month, year)
    Date.new(year, month, 1) > last_transaction_date
  end
end
