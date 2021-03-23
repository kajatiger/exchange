class OrderProcessor
  attr_accessor :order, :transaction, :validation_error

  def initialize(order, user_id, offer = nil)
    @order = order
    @offer = offer
    @user_id = user_id
    @validation_error = nil
    @transaction = nil
    @validated = false
    @totals_set = false
    @state_changed = false
    @original_state_expires_at = nil
    @payment_service = PaymentService.new(@order)
    @inventory_service = InventoryService.new(@order)
    @exempted_commission = false
  end

  def revert!(reversion_reason = nil)
    Rails.logger.warn("Order #{order.id}/#{order.code} reverted. Reason: #{reversion_reason}")
    undeduct_inventory!
    reset_totals! if @totals_set
    revert_debit_exemption(reversion_reason) if @exempted_commission
    return unless @state_changed

    order.revert!
    order.update!(state_expires_at: @original_state_expires_at)
    @state_changed = false
  end

  def advance_state(action)
    @original_state_expires_at = order.state_expires_at
    order.send(action)
    @state_changed = true
  end

  def set_totals!
    order.line_items.each { |li| li.update!(commission_fee_cents: li.current_commission_fee_cents) } if order.mode == Order::BUY
    totals = order.mode == Order::BUY ? BuyOrderTotals.new(@order) : OfferOrderTotals.new(@offer)
    order.update!(
      transaction_fee_cents: totals.transaction_fee_cents,
      commission_rate: order.current_commission_rate,
      commission_fee_cents: totals.commission_fee_cents,
      seller_total_cents: totals.seller_total_cents
    )

    @totals_set = true
  end

  def reset_totals!
    order.line_items.each { |li| li.update!(commission_fee_cents: nil) } if order.mode == Order::BUY
    order.update!(transaction_fee_cents: nil, commission_rate: nil, commission_fee_cents: nil, seller_total_cents: nil)
    @totals_set = false
  end

  def hold
    @transaction = if @order.external_charge_id
      # we already have a payment intent on this order
      @payment_service.confirm_payment_intent
    else
      @payment_service.hold
    end
  end

  def charge(off_session = false)
    @transaction = if @order.external_charge_id
      @payment_service.confirm_payment_intent
    else
      @payment_service.immediate_capture(off_session: off_session)
    end
  end

  def failed_payment?
    @transaction&.failed?
  end

  def requires_action?
    @transaction&.requires_action?
  end

  def action_data
    @transaction&.action_data
  end

  def valid?
    @validated ||= begin
      @validation_error = :unsupported_payment_method unless @order.payment_method == Order::CREDIT_CARD
      @validation_error ||= :missing_required_info unless @order.can_commit?
      @validation_error ||= @order.assert_credit_card
    end
    @validation_error.nil?
  end

  def deduct_inventory!
    @inventory_service.deduct_inventory! if @order.require_inventory?
  end

  def undeduct_inventory!
    @inventory_service.undeduct_inventory! if @order.require_inventory?
  end

  def store_transaction(off_session = false)
    order.transactions << transaction
    order.update!(external_charge_id: transaction.external_id) unless transaction.failed? || (transaction.requires_action? && off_session)
    PostTransactionNotificationJob.perform_later(transaction.id, @user_id)
  end

  def on_success
    OrderEvent.delay_post(order, @user_id)
    OrderFollowUpJob.set(wait_until: order.state_expires_at).perform_later(order.id, order.state)
    ReminderFollowUpJob.set(wait_until: order.state_expiration_reminder_time).perform_later(order.id, order.state)
    Exchange.dogstatsd.increment "order.#{order.state}"
  end

  # Call Gravity to check if the partner should be charged commission on this order and apply it if so
  def debit_commission_exemption(notes: '')
    gmv_to_exempt_and_currency_code = Gravity.debit_commission_exemption(partner_id: order.seller_id,
                                                                         amount_minor: order.items_total_cents,
                                                                         currency_code: order.currency_code,
                                                                         reference_id: order.id,
                                                                         notes: notes)
    return if gmv_to_exempt_and_currency_code.nil? || !gmv_to_exempt_and_currency_code.key?(:amount_minor) || gmv_to_exempt_and_currency_code[:amount_minor].zero?

    @exempted_commission = true
    apply_commission_exemption(gmv_to_exempt_and_currency_code[:amount_minor])
  rescue GravityGraphql::GraphQLError
    Rails.logger.error("Could not execute Gravity GraphQL query for order #{order.id}")
    nil
  end

  # Update commission on an order and line items
  def apply_commission_exemption(exemption_amount_cents)
    return unless exemption_amount_cents.positive?

    totals = order.mode == Order::BUY ? BuyOrderTotals.new(@order, commission_exemption_amount_cents: exemption_amount_cents) : OfferOrderTotals.new(@offer, commission_exemption_amount_cents: exemption_amount_cents)
    order.update!(seller_total_cents: totals.seller_total_cents, commission_fee_cents: totals.commission_fee_cents)
  end

  def revert_debit_exemption(reversion_reason)
    Gravity.refund_commission_exemption(partner_id: order.seller_id, reference_id: order.id, notes: reversion_reason)
    @exempted_commission = false
  end
end
