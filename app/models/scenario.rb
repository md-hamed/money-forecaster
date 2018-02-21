class Scenario < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :transactions
  has_many :incomes
  has_many :expenses

  # Validations
  validates :title, presence: true

  # Getters

  def income_of_month(month, year)
    last_available_transaction_amount(:income, month, year)
  end

  def expenses_of_month(month, year)
    last_available_transaction_amount(:expense, month, year)
  end

  def revenue_of_month(month, year)
    income_of_month(month, year) - expenses_of_month(month, year)
  end

  # returns cumulative total for all months
  # if a month and year are provided; it returns cumulative
  # total till the provided date
  def cumulative_total(month = nil, year = nil)
    gaps_total = gaps_total_amount(:income, month, year) - gaps_total_amount(:expenses, month, year)
    transactions_cumulative_total(month, year) + gaps_total
  end

  alias bank_balance cumulative_total

  # Actions

  def add_income(amount, year, month)
    add_transaction(:income, amount, year, month)
  end

  def add_expense(amount, year, month)
    add_transaction(:expense, amount, year, month)
  end

  private

  def last_available_transaction_amount(type, month, year)
    model = type.to_s.classify.constantize

    last_transaction_date = model.where(scenario: self)
                                 .where('issued_on <= ?', Date.new(year, month))
                                 .last.try(:issued_on)
    if last_transaction_date.present?
      amount = model.where(scenario: self)
                       .where(issued_on: last_transaction_date)
                       .sum(:amount_cents)
    end
    
    Money.new amount
  end

  def add_transaction(type, amount, year, month)
    date = Date.new(year, month, 1)
    model = type.to_s.classify.constantize
    money = Money.from_amount(amount)

    model.create(scenario: self,
                 amount: money,
                 issued_on: date)
  end

  def transactions_total_of_month(type, month, year)
    model = type.to_s.classify.constantize

    amount = model.where(scenario: self)
                  .where('issued_on = ?', Date.new(year, month, 1))
                  .sum(:amount_cents)
    Money.new amount
  end

  # get true available transactions cumulative total
  # till given month/year
  def transactions_cumulative_total(month, year)
    income_total = incomes
    expenses_total = expenses
    
    if month.present? && year.present?
      income_total = income_total.where('issued_on <= ?', Date.new(year, month, 1))
      expenses_total = expenses_total.where('issued_on <= ?', Date.new(year, month, 1))
    end

    Money.new(income_total.sum(:amount_cents) - expenses_total.sum(:amount_cents))
  end

  def gaps_total_amount(type, month = nil, year = nil)
    model = type.to_s.classify.constantize
    available_transactions = model.where(scenario: self).map(&:issued_on)
    available_dates = available_transaction_dates(type, month, year)
    
    gaps_total_amount = 0
    available_dates.each_cons(2).each do |prev, curr|
      curr_contains_transaction = available_transactions.include?(curr)

      if ((prev + 1.month) != curr) || !curr_contains_transaction # gap identified
        gap_length = (curr.year * 12 + curr.month) - (prev.year * 12 + prev.month)
        gap_length -= 1 if curr_contains_transaction
        gaps_total_amount += gap_length * transactions_total_of_month(type, prev.month, prev.year)
      end
    end

    gaps_total_amount
  end

  # transactions dates till the provided month/year
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
