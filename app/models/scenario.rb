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
    transactions_total_amount = Money.new(incomes.sum(:amount_cents) - expenses.sum(:amount_cents))
    gaps_total_amount = gaps_total_amount(:income, month, year) - gaps_total_amount(:expenses, month, year)

    transactions_total_amount + gaps_total_amount
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

  def gaps_total_amount(type, month = nil, year = nil)
    model = type.to_s.classify.constantize
    available_transactions = model.where(scenario: self).map(&:issued_on)

    available_dates = available_transaction_dates(type, month, year)
    
    if available_dates.length == 1
      return transactions_amount_on(type, available_dates.first.month,
                                    available_dates.first.year)
    end

    gaps_total_amount = 0
    available_dates.each_cons(2).each do |prev, curr|
      curr_contains_transaction = available_transactions.include?(curr)

      if ((prev + 1.month) != curr) || !curr_contains_transaction # gap identified
        gap_length = (curr.year * 12 + curr.month) - (prev.year * 12 + prev.month)
        gap_length -= 1 if curr_contains_transaction
        gaps_total_amount += gap_length * transactions_amount_on(type, prev.month, prev.year)
      end
    end

    gaps_total_amount
  end

  def available_transaction_dates(type, month, year)
    model = type.to_s.classify.constantize

    available_dates = model.where(scenario: self)
                           .order('issued_on ASC')

    if month.present? && year.present?
      end_date = Date.new(year, month)
    else
      end_date = transactions.maximum(:issued_on) # max transaction date
    end

    available_dates.where('issued_on <= ?', end_date)
                     .map(&:issued_on).push(end_date).uniq
  end
end
