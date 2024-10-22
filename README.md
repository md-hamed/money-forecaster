## Money Forecaster
A project to get insights and forecasts about how money behaves in differenc scenarios.

#### Ruby version
ruby-2.2.6

#### Rails version
5.1.4

#### Installation 
Just the normal installation path, nothing mysteriuos.
```
bundle
rake db:prepare
rails s
```
and tada :tada:

#### Examples 
Note: The following scenarios are based on the seeded user's first scenario; so make sure you've seeded the db.

##### Scenario 1
| May | June           | July  | August |
|:-----:|:-----:|:-----:|:-----:|
|+$1000| | |+$2000|
|+$500| | |+$1000|

All transactions are recurrent (monthly).

Let's play around this scenario:
###### Example 1
```
> s = User.first.scenarios.first
=> #<Scenario:0x0000000606ff80
  id: 32,
  title: "Scenario 1",
  created_at: Tue, 27 Feb 2018 22:26:33 UTC +00:00,
  updated_at: Tue, 27 Feb 2018 22:26:33 UTC +00:00,
  user_id: 1,
  current_date: Tue, 01 Aug 2017>
> s1 = s.duplicate
=> #<Scenario:0x00000005f616c0
  id: 34,
  title: "Scenario 1 copy",
  created_at: Tue, 27 Feb 2018 22:26:56 UTC +00:00,
  updated_at: Tue, 27 Feb 2018 22:26:56 UTC +00:00,
  user_id: 1,
  current_date: Tue, 01 Aug 2017>
> year_later_date = s1.current_date + 1.year
=> Wed, 01 Aug 2018
> # calculate how bank balance will be affected a year later with a 3% increase in income
> s1.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3)
=> #<Money fractional:1973558 currency:USD>
> _.format
=> "$28,853.36"
> # calculate how income will be affected a year later with a 3% increase in income
> s1.income_of_month(year_later_date.month, year_later_date.year, percent: 3).format
=> "$4,277.28"
> # calculate how income will be affected a year later (without an increase)
> s1.bank_balance(year_later_date.month, year_later_date.year).format
=> "$21,000.00"
> 3000 + (3000*12 - 1500*12)
=> 21000

> # let's duplicate this and have more fun ..
> fun_s = s1.duplicate
> # what if I added a fund of $10,000 on 6, 2017?
> fun_s.add_bank_balance(10_000, 6, 2017)
> fun_s.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3).format
=> "$38,853.36"
> # what about a yearly expense of $500 on 10, 2017?
> fun_s.add_expense(500, 10, 2017, payment_interval: :yearly)
=> #<Expense:0x00000005cb96c0
  id: 113,
  title: nil,
  type: "Expense",
  issued_on: Sun, 01 Oct 2017,
  scenario_id: 34,
  created_at: Tue, 27 Feb 2018 22:32:35 UTC +00:00,
  updated_at: Tue, 27 Feb 2018 22:32:35 UTC +00:00,
  amount_cents: 50000,
  amount_currency: "USD",
  schedule:
   "---\n:start_time: 2017-10-01 00:00:00.000000000 +02:00\n:rrules:\n- :validations: {}\n  :rule_type: IceCube::YearlyRule\n  :interval: 1\n:rtimes: []\n:extimes: []\n",
  ending_on: nil>
> fun_s.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3).format
=> "$38,353.36"
```
###### Example 2
```
> s2 = s1.duplicate
=> #<Scenario:0x000000057eafe0
  id: 40,
  title: "Scenario 1 copy copy",
  created_at: Tue, 27 Feb 2018 22:54:00 UTC +00:00,
  updated_at: Tue, 27 Feb 2018 22:54:00 UTC +00:00,
  user_id: 1,
  current_date: Tue, 01 Aug 2017>
> s2.current_date
=> Tue, 01 Aug 2017
> # add expense of $500 to the next year
> s2.first_forecasted_date
=> Fri, 01 Sep 2017
> year_later_date = s2.current_date + 1.year
=> Wed, 01 Aug 2018
> s2.add_expense(500, s2.first_forecasted_date.month, s2.first_forecasted_date.year, 'Rent', payment_interval: :monthly)
> #<Expense:0x000000042c8b08
  id: 143,
  title: "Rent",
  type: "Expense",
  issued_on: Fri, 01 Sep 2017,
  scenario_id: 40,
  created_at: Tue, 27 Feb 2018 23:13:38 UTC +00:00,
  updated_at: Tue, 27 Feb 2018 23:13:38 UTC +00:00,
  amount_cents: 50000,
  amount_currency: "USD",
  schedule:
   "---\n:start_time: 2017-09-01 00:00:00.000000000 +02:00\n:rrules:\n- :validations:\n    :day_of_month:\n    - 1\n  :rule_type: IceCube::MonthlyRule\n  :interval: 1\n:rtimes: []\n:extimes: []\n",
  ending_on: nil>
> # how will this affect my bank balance?
> s2.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3)
> "$22,853.36"
> # hmm.. interesting!
```
###### Example 3
```
> s = User.first.scenarios.first
=> #<Scenario:0x007f6bec13ec50
  id: 35,
  title: "Scenario 1",
  created_at: Tue, 27 Feb 2018 22:37:16 UTC +00:00,
  updated_at: Tue, 27 Feb 2018 22:37:16 UTC +00:00,
  user_id: 1,
  current_date: Tue, 01 Aug 2017>
> s3 = s.duplicate
=> #<Scenario:0x000000022bcdf0
  id: 41,
  title: "Scenario 1 copy",
  created_at: Tue, 27 Feb 2018 23:17:40 UTC +00:00,
  updated_at: Tue, 27 Feb 2018 23:17:40 UTC +00:00,
  user_id: 1,
  current_date: Tue, 01 Aug 2017>
> # what if a new income of $90 is added for every month through the next year?
> some_date = s3.first_forecasted_date + 3.months
=> Fri, 01 Dec 2017
> s3.add_income(90, some_date.month, some_date.year, 'Freelancing') # default is :one_payment
=> #<Income:0x000000061763e8
  id: 148,
  title: "Freelancing",
  type: "Income",
  issued_on: Fri, 01 Dec 2017,
  scenario_id: 41,
  created_at: Tue, 27 Feb 2018 23:19:33 UTC +00:00,
  updated_at: Tue, 27 Feb 2018 23:19:33 UTC +00:00,
  amount_cents: 9000,
  amount_currency: "USD",
  schedule: nil,
  ending_on: nil>
> year_later_date = s3.current_date + 1.year
=> Wed, 01 Aug 2018
> s3.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3).format
=> "$28,943.36"
```

###### Example 4
```
> s4 = Scenario.last.duplicate
=>  #<Scenario:0x0000000604b810
  id: 42,
  title: "Scenario 1 copy copy",
  created_at: Tue, 27 Feb 2018 23:21:25 UTC +00:00,
  updated_at: Tue, 27 Feb 2018 23:21:25 UTC +00:00,
  user_id: 1,
  current_date: Tue, 01 Aug 2017>
> s4.current_date
=> Tue, 01 Aug 2017
> s4.add_income(90, s4.first_forecasted_date.month, s4.first_forecasted_date.year, 'Freelancing', payment_interval: :monthly)
> #<Income:0x0000000596f488
  id: 155,
  title: "Freelancing",
  type: "Income",
  issued_on: Fri, 01 Sep 2017,
  scenario_id: 42,
  created_at: Tue, 27 Feb 2018 23:25:03 UTC +00:00,
  updated_at: Tue, 27 Feb 2018 23:25:03 UTC +00:00,
  amount_cents: 9000,
  amount_currency: "USD",
  schedule:
   "---\n:start_time: 2017-09-01 00:00:00.000000000 +02:00\n:rrules:\n- :validations:\n    :day_of_month:\n    - 1\n  :rule_type: IceCube::MonthlyRule\n  :interval: 1\n:rtimes: []\n:extimes: []\n",
  ending_on: nil>
> year_later_date = s4.current_date + 1.year
=> Wed, 01 Aug 2018
> s4.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3).format
=> "$30,023.36"
> # cool!
```

##### Scenario 2
| Type | 11/17 | 12/17 | 1/18 | 2/18 |
|:-------:|:-------:|:-------:|:-------:|:-------:|
| Income | Salary 1: $1000/month |Bonus: $1000/year|Salary 3: $1000/month||
|  | Salary 2: $500/month till 4/18 | | ||
| Bank balances | Bank balance 1: $1000 | | | |
| Expenses | Service 1: $500/month |Laptop purchase: $1000| |GitHub Subs: $300/year|

###### Example 5
```
> s5 = Scenario.find_by(title: 'Scenario 2')
=> #<Scenario:0x007f1500185a08
  id: 52,
  title: "Scenario 2",
  created_at: Wed, 28 Feb 2018 00:33:38 UTC +00:00,
  updated_at: Wed, 28 Feb 2018 00:33:38 UTC +00:00,
  user_id: 1,
  current_date: Thu, 01 Feb 2018>
> s5.current_date
=> Thu, 01 Feb 2018
> # what's my current bank balance?
> s5.bank_balance.format
=> "$6,700.00"
> 1000*4 + 500*4 + 1000 + 1000*2 + 1000 - (500*4 + 1000 + 300)
=> 6,700
> # what will my bank balance be in 4/18 with an income increase of 3% and an expense decrease of 5%?
> s5.bank_balance(4, 2018, income_percent: 3, expenses_percent: -5).format
=> "$11,001.00" 
> 6700 + ( 2*1000*(1.03**1) + 2*1000*(1.03**2) + 500*(1.03**1) + 500*(1.03**2) ) - (500*(0.95**1) + 500*(0.95**2))
=> 11001.0
> s5.bank_balance(5, 2018, income_percent: 3, expenses_percent: -5).format
=> "$12,757.77"
> 11_001.0 + (2000*(1.05**3)) - (500*(0.95**3))
=> 12757.7665
> # what will my bank balance be in 4/18 without change in income/expenses?
> s5.bank_balance(4, 2018).format
=> "$10,700.00"
> 6700 + ( 2*1000 + 2*1000 + 500 + 500 ) - (500 + 500)
=> 10700
```

###### Example 6
```
> # what if I need to delete a specefic transaction?
> s6 = s5.duplicate
=> #<Scenario:0x00000003dc2e88
  id: 61,
  title: "Scenario 2 copy",
  created_at: Thu, 01 Mar 2018 01:06:48 UTC +00:00,
  updated_at: Thu, 01 Mar 2018 01:06:48 UTC +00:00,
  user_id: 1,
  current_date: Thu, 01 Feb 2018>
> # say I don't need salary 3 anymore
> s6.transactions.find_by(title: 'Salary 3').delete
> # how this affects my bank balance?
> s6.bank_balance.format
=> "$4,700.00"
> 1000*4 + 500*4 + 1000 + 1000 - (500*4 + 1000 + 300)
=> 4700
> s6.bank_balance(4, 2018, income_percent: 3, expenses_percent: -5).format
=> "$6,910.10"
> 4700 + ( 1000*(1.03**1) + 1000*(1.03**2) + 500*(1.03**1) + 500*(1.03**2) ) - (500*(0.95**1) + 500*(0.95**2))
=> 6910.099999999999
> # what if I need to update a specefic transaction?
> s6.transactions.find_by(title: 'Salary 1 (permanent)').update(amount: Money.from_amount(3500))
> # how this affects my bank balance?
> s6.bank_balance.format
> "$14,700.00"
> 3500*4 + 500*4 + 1000 + 1000 - (500*4 + 1000 + 300)
> 14700
```
