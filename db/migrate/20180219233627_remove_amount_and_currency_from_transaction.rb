class RemoveAmountAndCurrencyFromTransaction < ActiveRecord::Migration[5.1]
  def change
    remove_column :transactions, :amount, :decimal
    remove_column :transactions, :currency, :string
  end
end
