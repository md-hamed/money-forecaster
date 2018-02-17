class AddUserIdToScenario < ActiveRecord::Migration[5.1]
  def change
    add_column :scenarios, :user_id, :integer
  end
end
