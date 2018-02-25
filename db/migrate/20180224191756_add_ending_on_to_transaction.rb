class AddEndingOnToTransaction < ActiveRecord::Migration[5.1]
  def change
    add_column :transactions, :ending_on, :Date
  end
end
