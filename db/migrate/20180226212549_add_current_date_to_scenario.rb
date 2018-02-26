class AddCurrentDateToScenario < ActiveRecord::Migration[5.1]
  def change
    add_column :scenarios, :current_date, :date
  end
end
