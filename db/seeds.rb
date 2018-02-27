# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

puts 'Seeding User ..'
user = User.first_or_create(email: 'foo@bar.com', password: '123456789')

puts 'Creating Scenario 1 ..'
scenario = user.scenarios.first_or_create(title: 'Scenario 1', current_date: Date.new(2017, 8))

if scenario.transactions.none?
  puts 'Adding Transactions to Scenario 1..'
  scenario.add_income(1000, 5, 2017, 'Salary 1', payments_type: :monthly)
  scenario.add_expense(500, 5, 2017, 'Serviec 1', payments_type: :monthly)

  scenario.add_income(2000, 8, 2017, 'Salary 2', payments_type: :monthly)
  scenario.add_expense(1000, 8, 2017, 'Serviec 2', payments_type: :monthly)
end

# cumulative total on 8, 2017 = $3,000
# cumulative total on 9, 2017 = $4,500

puts 'Creating Scenario 2 ..'
scenario = user.scenarios.create(title: 'Scenario 2', current_date: Date.new(2018, 2))

if scenario.transactions.none?
  puts 'Adding Transactions to Scenario 2..'
  scenario.add_income(1000, 11, 2017, 'Salary 1 (permanent)', payments_type: :monthly)
  scenario.add_income(500, 11, 2017, 'Salary 2 (non-permanent)', ending_month: 5, ending_year: 2018, payments_type: :monthly)
  scenario.add_income(1000, 12, 2017, 'Year bonus', payments_type: :yearly)
  scenario.add_income(1000, 1, 2018, 'Salary 3', payments_type: :monthly)

  scenario.add_expense(500, 11, 2017, 'Service 1', payments_type: :monthly)
  scenario.add_expense(1000, 12, 2017, 'Laptop purchase', payments_type: :one_time)
end

# cumulative total on 2, 2018 = $6,000
# cumulative total on 3, 2018 = $8075 (with 3% raise)
