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
    min_period_date, max_period_date = longest_period(month, year)

    # loop from min period date to max period date
    current_date = min_period_date
    cumulative_total = 0
    prev_month_income = 0
    prev_month_expenses = 0
    while current_date != (max_period_date + 1.month) do
      month_income, prev_month_income, prev_month_expenses = month_cumulative_total(prev_month_income, prev_month_expenses, current_date)
      cumulative_total += month_income
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
    money = Money.from_amount(amount)

    model.create(scenario: self,
                 amount: money,
                 issued_on: date)
  end

  # helper method to get transactions
  # of specefic type on a date
  def transactions_amount_on(type, month, year)
    model = type.to_s.classify.constantize

    amount = model.where(scenario: self)
                  .where('extract(month from issued_on) = ?', month)
                  .where('extract(year from issued_on) = ?', year)
                  .sum(:amount_cents)
    Money.new amount
  end

  # helper method to return true available
  # transactions cumulative total
  def true_cumulative_total
    incomes.sum(:amount_cents) - expenses.sum(:amount_cents)
  end

  # helper method to return lonest available
  # period of time where transactions exist
  def longest_period(month = nil, year = nil)
    first_transaction_date = transactions.minimum(:issued_on)

    if month.present? && year.present?
      last_transaction_date = Date.new(year, month, 1)
      if last_transaction_date < first_transaction_date
        raise ArgumentError, "Provided date #{last_transaction_date} can not be less than first transaction date #{first_transaction_date}"
      end
    else
      last_transaction_date = transactions.maximum(:issued_on)
    end

    [first_transaction_date, last_transaction_date]
  end

  # helper method to return month cumulative
  # total given the knwoledge of previuos month
  def month_cumulative_total(prev_month_income, prev_month_expenses, date)
    income = income_on(date.month, date.year)
    expenses = expenses_on(date.month, date.year)

    income = prev_month_income if income.zero?
    expenses = prev_month_expenses if expenses.zero?

    [income - expenses, income, expenses]
  end
end
