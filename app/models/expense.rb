class Expense < Transaction
  def signed_amount
    -amount
  end
end
