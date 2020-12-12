module OfferService
  def self.create_pending_offer(
    order,
    amount_cents:,
    note:,
    from_id:,
    from_type:,
    creator_id:,
    responds_to: nil
  )
    unless order.mode == Order::OFFER
      raise Errors::ValidationError, :cannot_offer
    end
    unless amount_cents.positive?
      raise Errors::ValidationError, :invalid_amount_cents
    end

    offer_totals = OfferTotals.new(order, amount_cents)
    order.offers.create!(
      amount_cents: amount_cents,
      from_id: from_id,
      from_type: from_type,
      creator_id: creator_id,
      responds_to: responds_to,
      shipping_total_cents: offer_totals.shipping_total_cents,
      tax_total_cents: offer_totals.tax_total_cents,
      should_remit_sales_tax: offer_totals.should_remit_sales_tax,
      note: note
    )
  end

  def self.create_pending_counter_offer(
    responds_to,
    amount_cents:,
    note:,
    from_id:,
    from_type:,
    creator_id:
  )
    unless responds_to.order.state == Order::SUBMITTED
      raise Errors::ValidationError, :invalid_state
    end
    unless responds_to.last_offer?
      raise Errors::ValidationError, :not_last_offer
    end

    create_pending_offer(
      responds_to.order,
      amount_cents: amount_cents,
      note: note,
      from_id: from_id,
      from_type: from_type,
      creator_id: creator_id,
      responds_to: responds_to
    )
  end

  def self.submit_pending_offer(offer)
    op = OfferProcessor.new(offer)
    op.validate_offer!
    op.check_inventory!
    op.update_offer_submission_timestamp
    op.set_order_totals!
    op.on_success
    offer
  end

  def self.submit_order_with_offer(
    offer,
    user_id:,
    confirmed_setup_intent_id: nil
  )
    op = OfferProcessor.new(offer, user_id)
    op.validate_offer!
    op.validate_order!
    op.check_inventory!
    op.confirm_payment_method!(confirmed_setup_intent_id)
    op.submit_order!
    op.update_offer_submission_timestamp
    op.set_order_totals!
    op.on_success
    op.order_on_success
  end

  def self.accept_offer(offer, user_id)
    raise Errors::ValidationError, :not_last_offer unless offer.last_offer?

    order = offer.order
    order_processor = OrderProcessor.new(order, user_id, offer)
    unless order_processor.valid?
      raise Errors::ValidationError, order_processor.validation_error
    end

    order_processor.advance_state(:approve!)
    unless order_processor.deduct_inventory
      raise Errors::InsufficientInventoryError
    end

    # this is an off-session if offer is from buyer and seller is accepting it (in case of failed payment buyer could accept their own offer)
    off_session =
      offer.from_participant == Order::BUYER && user_id != order.buyer_id

    order_processor.debit_commission_exemption

    order_processor.charge(off_session)
    order_processor.store_transaction(off_session)
    if order_processor.failed_payment?
      raise Errors::FailedTransactionError.new(
              :capture_failed,
              order_processor.transaction
            )
    end

    if order_processor.requires_action?
      raise Errors::PaymentRequiresActionError, order_processor.action_data
    end

    order_processor.on_success
    order
  rescue StandardError => e
    # catch all
    order_processor&.revert!
    raise e
  end
end
