class AddScheduleToTransaction < ActiveRecord::Migration[5.1]
  def change
    add_column :transactions, :schedule, :string
  end
end
