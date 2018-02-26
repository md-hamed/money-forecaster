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
scenario = user.scenarios.first_or_create(title: 'Scenario 1')

if scenario.transactions.none?
  puts 'Adding Transactions to Scenario 1..'
  scenario.add_income(1000, 5, 2017, 'Salary 1', ending_month: 5, ending_year: 2030)
  scenario.add_expense(500, 5, 2017, 'Serviec 1', ending_month: 5, ending_year: 2030)

  scenario.add_income(2000, 8, 2017, 'Salary 2', ending_month: 5, ending_year: 2030)
  scenario.add_expense(1000, 8, 2017, 'Serviec 2', ending_month: 5, ending_year: 2030)
end

# cumulative total on 8, 2017 = 3000
# cumulative total on 9, 2017 = 4500

puts 'Seeding User ..'
scenario = user.scenarios.create(title: 'Scenario 2')

puts 'Creating Scenario 2 ..'
scenario.add_income(1000, 5, 2017, 'Salary 1', ending_month: 5, ending_year: 2030)
scenario.add_expense(500, 7, 2017, 'Service 1', ending_month: 5, ending_year: 2030)

puts 'Adding Transactions to Scenario 2..'
scenario.add_income(2000, 10, 2017, 'Freelancing')
scenario.add_expense(1000, 9, 2017, 'Serviec 2', ending_month: 5, ending_year: 2030)

# cumulative total on 10, 2017 = 4000
# cumulative total on 11, 2017 = 3500
