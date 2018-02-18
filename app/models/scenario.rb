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
    transactions_on(:income, month, year)
  end

  # expenses of specefic month/year
  def expenses_on(month, year)
    transactions_on(:expenses, month, year)
  end

  # revenue of specefic month/year
  def revenue_on(month, year)
    income_on(month, year) - expenses_on(month, year)
  end

  # returns cumulative total for all months
  # if a month and year are provided; it returns cumulative
  # total till the provided date
  def cumulative_total(month = nil, year = nil)
    # TODO
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
  def transactions_on(type, month, year)
    model = type.to_s.classify.constantize

    model.where('extract(month from issued_on) = ?', month)
         .where('extract(year from issued_on) = ?', year)
         .sum(:amount)
  end
end
