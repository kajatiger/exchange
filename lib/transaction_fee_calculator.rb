module TransactionFeeCalculator
  def self.calculate(total_charge_amount, currency)
    0 unless total_charge_amount&.positive?

    # This is based on Stripe fee, we decided to charge unified 3.9% + 30 cents across all countries
    (
      Money.new(total_charge_amount * 3.9 / 100, currency) +
        Money.new(30, currency)
    ).cents
  end
end
