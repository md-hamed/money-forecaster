
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
|+$1000|//|//|+$2000|
|+$500|//|//|+$1000|
`//` indicates a gap filling. i.e. the amount is similar to the last available month.
Let's play around this scenario:
###### Example 1
```
> s = User.first.scenarios.first
=> #<Scenario:0x0000000437a9e8
  id: 55,
  title: "Scenario 1",
  created_at: Mon, 26 Feb 2018 02:09:13 UTC +00:00,
  updated_at: Mon, 26 Feb 2018 02:09:13 UTC +00:00,
  user_id: 15>
> s1 = s.duplicate
=> # queries ..
=> #<Scenario:0x00000005108038
   id: 19,
   title: "Scenario 1 copy",
   created_at: Fri, 23 Feb 2018 01:38:02 UTC +00:00,
   updated_at: Fri, 23 Feb 2018 01:38:02 UTC +00:00,
   user_id: 5>
> year_later_date = s1.last_transaction_date + 1.year
=> Wed, 01 Aug 2018
> # calculate how bank balance will be affected a year later with a 3% increase in income
> s1.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3)
=> #<Money fractional:1973558 currency:USD>
> _.format
=> "$28,853.36"
> s1.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3, include_known_months: false).format
=> "$25,853.36"
> # calculate how income will be affected a year later with a 3% increase in income
> s1.income_of_month(year_later_date.month, year_later_date.year, percent: 3).format
=> "$4,277.28"
```
###### Example 2
```
> s2 = Scenario.last.duplicate
=> #<Scenario:0x0000000526a1d8
   id: 21,
   title: "Scenario 1 copy copy",
   created_at: Fri, 23 Feb 2018 02:07:27 UTC +00:00,
   updated_at: Fri, 23 Feb 2018 02:07:27 UTC +00:00,
   user_id: 5>
> s2.last_transaction_date
=> Tue, 01 Aug 2017
> # add expense of $500 on the last month where transactions are available
> # this has the effect of duplication over the next year
> s2.add_expense(500, s2.last_transaction_date.month, s2.last_transaction_date.year, 'Rent')
> #<Expense:0x00000005a024e0
   id: 99,
   title: "Rent",
   type: "Expense",
   issued_on: Tue, 01 Aug 2017,
   scenario_id: 21,
   created_at: Fri, 23 Feb 2018 02:12:43 UTC +00:00,
   updated_at: Fri, 23 Feb 2018 02:12:43 UTC +00:00,
   amount_cents: 50000,
   amount_currency: "USD">
> # how will this affect my bank balance?
> year_later_date = s2.last_transaction_date + 1.year
=> Wed, 01 Aug 2018
> s2.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3)
=> "$13,235.58" 
> s2.expenses_of_month(year_later_date.month, year_later_date.year, percent: 3).format
=> "$2,138.64"
> # hmm.. interesting!
```
###### Example 3
```
> s = User.first.scenarios.first
=> #<Scenario:0x007fe7fc0d5ae8
   id: 17,
   title: "Scenario 1",
   created_at: Fri, 23 Feb 2018 01:36:53 UTC +00:00,
   updated_at: Fri, 23 Feb 2018 01:36:53 UTC +00:00,
   user_id: 5>
> s3 = s.duplicate
=> # queries ..
=> #<Scenario:0x00000005339e10
   id: 39,
   title: "Scenario 1 copy",
   created_at: Fri, 23 Feb 2018 03:00:59 UTC +00:00,
   updated_at: Fri, 23 Feb 2018 03:00:59 UTC +00:00,
   user_id: 8>
> some_date = s3.last_transaction_date - 1.month
=> Sat, 01 Jul 2017
# what if a new income of $90 is added for every month through the next year?
> s3.add_income(90, some_date.month, some_date.year, 'Freelancing')
=> #<Income:0x00000004e025f0
   id: 201,
   title: "Freelancing",
   type: "Income",
   issued_on: Sat, 01 Jul 2017,
   scenario_id: 44,
   created_at: Fri, 23 Feb 2018 03:07:43 UTC +00:00,
   updated_at: Fri, 23 Feb 2018 03:07:43 UTC +00:00,
   amount_cents: 9000,
   amount_currency: "USD">
> year_later_date = s3.last_transaction_date + 1.year
=> Wed, 01 Aug 2018
> s3.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3).format
=> "$18,825.58"
> # wait.. how? 
> s3.add_income(1000, some_date.month, some_date.year, 'Freelancing')
=> "$19,825.58"
```

###### Example 4
```
> s4 = Scenario.last.duplicate
=> #<Scenario:0x00000005657bb0
   id: 45,
   title: "Scenario 1 copy copy",
   created_at: Fri, 23 Feb 2018 03:13:22 UTC +00:00,
   updated_at: Fri, 23 Feb 2018 03:13:22 UTC +00:00,
   user_id: 9>
> s4.last_transaction_date
=> Tue, 01 Aug 2017
> s4.add_income(90, s4.last_transaction_date.month, s4.last_transaction_date.year, 'Freelancing')
> #<Income:0x00000005377a80
   id: 209,
   title: "Freelancing",
   type: "Income",
   issued_on: Tue, 01 Aug 2017,
   scenario_id: 45,
   created_at: Fri, 23 Feb 2018 03:14:27 UTC +00:00,
   updated_at: Fri, 23 Feb 2018 03:14:27 UTC +00:00,
   amount_cents: 9000,
   amount_currency: "USD">
> year_later_date = s4.last_transaction_date + 1.year
=> Wed, 01 Aug 2018
> s4.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3).format
=> "$21,231.19"
```
