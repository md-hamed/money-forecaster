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
|$1000|//|//|$2000|
|$500|//|//|$1000|
`//` indicates a gap filling. i.e. the amount is similar to the last available month.
Let's play around this scenario:
###### Example 1
```
> s = User.first.scenarios.first
=> #<Scenario:0x007fe7fc0d5ae8
   id: 17,
   title: "Scenario 1",
   created_at: Fri, 23 Feb 2018 01:36:53 UTC +00:00,
   updated_at: Fri, 23 Feb 2018 01:36:53 UTC +00:00,
   user_id: 5>
> s1 = s.duplicate
=> # queries ..
=> #<Scenario:0x00000005108038
   id: 19,
   title: "Scenario 1 copy",
   created_at: Fri, 23 Feb 2018 01:38:02 UTC +00:00,
   updated_at: Fri, 23 Feb 2018 01:38:02 UTC +00:00,
   user_id: 5>
> year_later_date = s1.transactions.last.issued_on + 1.year
=> Wed, 01 Aug 2018
> # calculate how bank balance will be affected a year later with a 3% increase in income
> s1.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3)
=> #<Money fractional:1973558 currency:USD>
> _.format
=> "$19,735.58"
> # calculate how income will be affected a year later with a 3% increase in income
> s1.income_of_month(year_later_date.month, year_later_date.year, percent: 3).format
=> "$2,851.52"
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
> last_transaction_date = s2.transactions.last.issued_on
=> Tue, 01 Aug 2017
> # add expense of $500 on the last month where transactions are available
> s2.add_expense(500, last_transaction_date.month, last_transaction_date.year, 'Rent')
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
> year_later_date = last_transaction_date + 1.year
=> Wed, 01 Aug 2018
> s2.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3)
> "$13,235.58" 
> 
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
=> #<Scenario:0x00000002c26dc8
   id: 38,
   title: "Scenario 1 copy",
   created_at: Fri, 23 Feb 2018 02:46:23 UTC +00:00,
   updated_at: Fri, 23 Feb 2018 02:46:23 UTC +00:00,
   user_id: 8>
> last_transaction_date = s3.transactions.last.issued_on
=> Tue, 01 Aug 2017
# what if a new income of $90 is added?
> s3.add_income(90, last_transaction_date.month, last_transaction_date.year, 'Freelancing')
=> #<Income:0x00000005ba4ed8
   id: 174,
   title: "Freelancing",
   type: "Income",
   issued_on: Tue, 01 Aug 2017,
   scenario_id: 38,
   created_at: Fri, 23 Feb 2018 02:47:00 UTC +00:00,
   updated_at: Fri, 23 Feb 2018 02:47:00 UTC +00:00,
   amount_cents: 9000,
   amount_currency: "USD">
> year_later_date = last_transaction_date + 1.year
=> Wed, 01 Aug 2018
> s3.bank_balance(year_later_date.month, year_later_date.year, income_percent: 3).format
=> "$21,141.19"
```
