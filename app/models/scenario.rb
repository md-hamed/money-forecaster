class Scenario < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :transactions
  has_many :incomes
  has_many :expenses

  # Validations
  validates :title, presence: true

  # Getters

  def income_of_month(month, year, percent: 0.0)
    amount = last_available_transaction_amount(:income, month, year)
    forecasting?(month, year) ? raised_amount(amount, percent, month, year) : amount
  end

  def expenses_of_month(month, year, percent: 0.0)
    amount = last_available_transaction_amount(:expense, month, year)
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
    gaps_total = total_gaps_amount(:income, month, year, percent: income_percent) - total_gaps_amount(:expenses, month, year, percent: expenses_percent)
    total_cumulative_transactions(month, year) + gaps_total
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

  def total_transactions_of_month(type, month, year)
    model = type.to_s.classify.constantize

    amount = model.where(scenario: self)
                  .where('issued_on = ?', Date.new(year, month, 1))
                  .sum(:amount_cents)
    Money.new amount
  end

  # get true available transactions cumulative total
  # till given month/year
  def total_cumulative_transactions(month, year)
    income_total = incomes
    expenses_total = expenses
    
    if month.present? && year.present?
      income_total = income_total.where('issued_on <= ?', Date.new(year, month, 1))
      expenses_total = expenses_total.where('issued_on <= ?', Date.new(year, month, 1))
    end

    Money.new(income_total.sum(:amount_cents) - expenses_total.sum(:amount_cents))
  end

  def total_gaps_amount(type, month = nil, year = nil, percent: 0.0)
    model = type.to_s.classify.constantize
    available_transactions = model.where(scenario: self).map(&:issued_on)
    available_dates = dates_with_transactions_available(type, month, year)
    
    total_gaps_amount = 0
    available_dates.each_cons(2).each do |prev, curr|
      curr_contains_transaction = available_transactions.include?(curr)

      if ((prev + 1.month) != curr) || !curr_contains_transaction # gap identified
        gap_length = months_difference(curr, prev)
        gap_length -= 1 if curr_contains_transaction
        total_transactions = total_transactions_of_month(type, prev.month, prev.year)

        if forecasting?(curr.month, curr.year) && !percent.zero?
          forecasted_months_count = months_difference(curr, last_transaction_date)
          non_forecasted_months = gap_length - forecasted_months_count
          first_forecasted_month = last_transaction_date + 1.month

          forecasted_months_count.times do |i|
            total_gaps_amount += raised_amount(total_transactions, percent, (first_forecasted_month + i.months).month, (first_forecasted_month + i.months).year)
          end
          total_gaps_amount += non_forecasted_months * total_transactions
        else
          total_gaps_amount += gap_length * total_transactions
        end
      end
    end

    total_gaps_amount
  end

  # transactions dates till the provided month/year
  def dates_with_transactions_available(type, month, year)
    model = type.to_s.classify.constantize

    available_dates = model.where(scenario: self)
                           .order('issued_on ASC')

    if month.present? && year.present?
      end_date = Date.new(year, month)
    else
      end_date = last_transaction_date
    end

    available_dates.where('issued_on <= ?', end_date)
                     .map(&:issued_on).push(end_date).uniq
  end

  def last_transaction_date
    transactions.maximum(:issued_on)
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
