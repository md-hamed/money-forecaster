# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

puts 'Seeding User ..'
user = User.create(email: 'foo@bar.com', password: '123456789')

puts 'Creating Scenario 1 ..'
scenario = user.scenarios.create(title: 'Scenario 1')

puts 'Adding Transactions to Scenario 1..'
scenario.add_income(1000, 2017, 5, 'Salary 1')
scenario.add_expense(500, 2017, 5, 'Salary 2')

scenario.add_income(2000, 2017, 8, 'Serviec 1')
scenario.add_expense(1000, 2017, 8, 'Serviec 1')

# cumulative revenue on 8, 2017 = 2500
# cumulative revenue on 9, 2017 = 3500

puts 'Seeding User ..'
scenario = user.scenarios.create(title: 'Scenario 2')

puts 'Creating Scenario 2 ..'
scenario.add_income(1000, 2017, 5, 'Salary 1')
scenario.add_expense(500, 2017, 7, 'Salary 1')

puts 'Adding Transactions to Scenario 2..'
scenario.add_income(2000, 2017, 10, 'Serviec 1')
scenario.add_expense(1000, 2017, 9, 'Serviec 1')

# cumulative revenue on 10, 2017 = 4000
# cumulative revenue on 11, 2017 = 5000
