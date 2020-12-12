module PaymentMethodService
  def self.verify_payment_method(setup_intent_id)
    setup_intent = Stripe::SetupIntent.retrieve(setup_intent_id)
    Transaction.new(
      external_id: setup_intent.id,
      external_type: Transaction::SETUP_INTENT,
      source_id: setup_intent.payment_method,
      destination_id: setup_intent.on_behalf_of,
      amount_cents: nil,
      transaction_type: Transaction::CONFIRM,
      status: transaction_status_from_intent(setup_intent),
      payload: setup_intent.to_h
    )
  end

  def self.confirm_payment_method!(order)
    credit_card = order.credit_card
    merchant_account = order.merchant_account
    setup_intent =
      Stripe::SetupIntent.create(
        payment_method_types: ['card'],
        confirm: true,
        customer: credit_card[:customer_account][:external_id],
        on_behalf_of: merchant_account[:external_id],
        payment_method: credit_card[:external_id],
        usage: 'off_session',
        metadata: metadata(order)
      )
    Transaction.new(
      external_id: setup_intent.id,
      external_type: Transaction::SETUP_INTENT,
      source_id: setup_intent.payment_method,
      destination_id: merchant_account[:external_id],
      amount_cents: order.items_total_cents,
      transaction_type: Transaction::CONFIRM,
      status: transaction_status_from_intent(setup_intent),
      payload: setup_intent.to_h
    )
  rescue Stripe::CardError => e
    body = e.json_body[:error]
    Transaction.new(
      external_id: body[:setup_intent][:id],
      external_type: Transaction::SETUP_INTENT,
      failure_code: body[:code],
      failure_message: body[:message],
      decline_code: body[:decline_code],
      transaction_type: Transaction::CONFIRM,
      status: Transaction::FAILURE,
      payload: e.json_body
    )
  end

  def self.metadata(order)
    {
      exchange_order_id: order.id,
      buyer_id: order.buyer_id,
      buyer_type: order.buyer_type,
      seller_id: order.seller_id,
      seller_type: order.seller_type,
      type: order.auction_seller? ? 'auction-bn' : 'bn-mo',
      mode: order.mode
    }
  end

  def self.transaction_status_from_intent(setup_intent)
    case setup_intent.status # https://stripe.com/docs/payments/intents#intent-statuses
    when 'requires_capture'
      Transaction::REQUIRES_CAPTURE
    when 'requires_action'
      Transaction::REQUIRES_ACTION
    when 'succeeded'
      Transaction::SUCCESS
    else
      # unknown status raise error
      raise "Unsupported setup_intent status: #{setup_intent.status}"
    end
  end
end
