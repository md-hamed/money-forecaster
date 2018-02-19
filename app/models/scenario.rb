class Scenario < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :transactions
  has_many :incomes
  has_many :expenses

  # Validations
  validates :title, presence: true

  # Getters

  # income of specefic month/year
  def income_on(month, year)
    transactions_amount_on(:income, month, year)
  end

  # expenses of specefic month/year
  def expenses_on(month, year)
    transactions_amount_on(:expenses, month, year)
  end

  # revenue of specefic month/year
  def revenue_on(month, year)
    income_on(month, year) - expenses_on(month, year)
  end

  # returns cumulative total for all months
  # if a month and year are provided; it returns cumulative
  # total till the provided date
  def cumulative_total(month = nil, year = nil)
    first_available_income = incomes.minimum(:issued_on)
    first_available_expense = expenses.minimum(:issued_on)

    if month.present? && year.present?
      date = Date.new(year, month, 1)
      last_available_expense = last_available_income = date
    else
      last_available_income = incomes.maximum(:issued_on)
      last_available_expense = expenses.maximum(:issued_on)
    end

    min_period_date = [first_available_income, first_available_expense].min
    max_period_date = [last_available_income, last_available_expense].max

    # loop from min period date to max period date
    current_date = min_period_date
    cumulative_total = 0
    prev_month_income = 0
    while current_date != (max_period_date + 1.month) do
      
      month_income = revenue_on(current_date.month, current_date.year)

      month_income = prev_month_income if month_income == 0
      cumulative_total += month_income
      prev_month_income = month_income

      current_date += 1.month
    end

    cumulative_total
  end

  alias bank_balance cumulative_total

  # Actions

  # adds income amount for a month
  # amount is a float
  # year ex: 2015, 2016, etc.
  # month ex: 1, 02, 11, etc.
  def add_income(amount, year, month)
    add_transaction(:income, amount, year, month)
  end

  # adds expense amount for a month
  # amount is a float
  # year ex: 2015, 2016, etc.
  # month ex: 1, 02, 11, etc.
  def add_expense(amount, year, month)
    add_transaction(:expense, amount, year, month)
  end

  # increases income of current month
  def increase_income_by(amount)
    add_income(amount, Date.today.year, Date.today.month)
  end

  # increases expenses of current month
  def increase_expenses_by(amount)
    add_expense(amount, Date.today.year, Date.today.month)
  end

  private

  # helper method to add transaction
  # with specefic type on a date
  def add_transaction(type, amount, year, month)
    date = Date.new(year, month, 1)
    model = type.to_s.classify.constantize

    model.create(scenario: self,
                 amount: amount,
                 issued_on: date)
  end

  # helper method to get transactions
  # of specefic type on a date
  def transactions_amount_on(type, month, year)
    model = type.to_s.classify.constantize

    model.where('extract(month from issued_on) = ?', month)
         .where('extract(year from issued_on) = ?', year)
         .sum(:amount)
  end

  def true_cumulative_revenue
    incomes.sum(:amount) - expenses.sum(:amount)
  end
end
