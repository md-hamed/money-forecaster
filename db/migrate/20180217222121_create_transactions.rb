class CreateTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :transactions do |t|
      t.string :title
      t.decimal :amount, precision: 8, scale: 2, default: 0
      t.string :currency, default: 'USD'
      t.string :type
      t.date :issued_on
      t.integer :scenario_id

      t.timestamps
    end
  end
end
