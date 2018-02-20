class AddAndCurrencyToTransaction < ActiveRecord::Migration[5.1]
  def change
    add_monetize :transactions, :amount
  end
end
