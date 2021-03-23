require 'rails_helper'
require 'support/gravity_helper'
require 'support/taxjar_helper'

describe 'Inquiry Checkout happy path with missing artwork metadata', type: :request do
  include_context 'GraphQL Client Helpers'

  let(:buyer_id) { 'gravity-user-id' }
  let(:buyer_client) { graphql_client(user_id: buyer_id, partner_ids: [], roles: 'user') }
  let(:seller_id) { 'gravity-partner-id' }
  let(:seller_client) { graphql_client(user_id: 'partner_admin_id', partner_ids: [seller_id], roles: 'user') }
  let(:impulse_conversation_id) { '401' }
  let(:artwork) do
    gravity_v1_artwork(
      _id: 'artwork_1',
      price_listed: 1000.00,
      edition_sets: [],
      domestic_shipping_fee_cents: nil,
      international_shipping_fee_cents: nil,
      inventory: nil
    )
  end
  let(:buyer_shipping_address) do
    {
      name: 'Fname Lname',
      country: 'US',
      city: 'New York',
      region: 'NY',
      postalCode: '10012',
      phoneNumber: '617-718-7818',
      addressLine1: '401 Broadway',
      addressLine2: 'Suite 80'
    }
  end
  let(:buyer_credit_card) do
    {
      id: 'credit_card_1',
      user: { _id: buyer_id },
      external_id: 'card_1',
      customer_account: { external_id: 'cust_1' }
    }
  end

  before do
    allow(Gravity).to receive_messages(
      get_artwork: artwork,
      get_credit_card: buyer_credit_card
    )
  end

  it 'supports buyer submitting an offer, seller adding missing metadata, and buyer accepting it' do
    buyer_creates_pending_offer_order
    buyer_adds_initial_offer_to_oder
    buyer_sets_shipping
    buyer_sets_credit_card
    buyer_submits_offer_order
    seller_counters_with_missing_data_provided
    buyer_accepts_offer
  end

  def buyer_creates_pending_offer_order
    create_inquiry_offer_order_input = { artworkId: artwork[:_id], quantity: 1, impulseConversationId: impulse_conversation_id }
    expect do
      buyer_client.execute(OfferQueryHelper::CREATE_INQUIRY_OFFER_ORDER, input: create_inquiry_offer_order_input)
    end.to change(Order, :count).by(1)

    order = Order.last
    expect(order).to have_attributes(
      state: Order::PENDING,
      mode: Order::OFFER,
      impulse_conversation_id: '401',
      items_total_cents: nil,
      shipping_total_cents: nil,
      tax_total_cents: nil,
      buyer_total_cents: nil,
      seller_total_cents: nil
    )
  end

  def buyer_adds_initial_offer_to_oder
    order = Order.last

    add_offer_to_order_input = { orderId: order.id, amountCents: 500_00 }
    expect do
      buyer_client.execute(OfferQueryHelper::ADD_OFFER_TO_ORDER, input: add_offer_to_order_input)
    end.to change(Offer, :count).by(1)

    expect(order.reload).to have_attributes(
      state: Order::PENDING,
      mode: Order::OFFER,
      impulse_conversation_id: '401',
      items_total_cents: nil,
      shipping_total_cents: nil,
      tax_total_cents: nil,
      buyer_total_cents: nil,
      seller_total_cents: nil
    )
    offer = Offer.last
    expect(offer).to have_attributes(
      amount_cents: 500_00,
      order_id: order.id,
      shipping_total_cents: nil,
      tax_total_cents: nil,
      buyer_total_cents: nil
    )
  end

  def buyer_sets_shipping
    order = Order.last

    # TODO: feat: support setting shipping with missing artwork location and shipping costs. This mocks out shipping
    # and tax calcualtion for now.
    allow_any_instance_of(OfferTotals).to receive_messages(
      shipping_total_cents: nil,
      tax_total_cents: nil,
      should_remit_sales_tax: false
    )
    # TODO: refactor: `id` should be `orderId` to be consistent
    set_shipping_input = { id: order.id.to_s, fulfillmentType: 'SHIP', shipping: buyer_shipping_address }
    expect do
      buyer_client.execute(QueryHelper::SET_SHIPPING, input: set_shipping_input)
    end.to_not change(Offer, :count)

    expect(order.reload).to have_attributes(
      state: Order::PENDING,
      mode: Order::OFFER,
      impulse_conversation_id: '401',
      fulfillment_type: Order::SHIP,
      items_total_cents: nil,
      shipping_total_cents: nil,
      tax_total_cents: nil,
      buyer_total_cents: nil,
      shipping_country: 'US',
      shipping_city: 'New York',
      shipping_address_line1: '401 Broadway',
      shipping_address_line2: 'Suite 80',
      shipping_postal_code: '10012'
    )

    offer = Offer.last
    expect(offer).to have_attributes(
      amount_cents: 500_00,
      shipping_total_cents: nil,
      tax_total_cents: nil,
      buyer_total_cents: nil
    )
  end

  def buyer_sets_credit_card
    order = Order.last

    # TODO: refactor: `id` should be `orderId` to be consistent
    set_credit_card_input = { id: order.id.to_s, creditCardId: buyer_credit_card[:id] }
    buyer_client.execute(QueryHelper::SET_CREDIT_CARD, input: set_credit_card_input)

    expect(order.reload).to have_attributes(
      state: Order::PENDING,
      fulfillment_type: Order::SHIP,
      shipping_country: 'US',
      credit_card_id: 'credit_card_1'
    )
  end

  def buyer_submits_offer_order
    order = Order.last

    # TODO: feat: allow deferring setting order totals in this step because we don't have shipping or tax info.
    # TODO: question: after offer order submitted, do we also ask partners to respond (with missing
    # metadata/accept/counter/reject) in x hours (i.e. the same expiration rules)?
    allow_any_instance_of(OfferProcessor).to receive_messages(
      confirm_payment_method!: nil,
      set_order_totals!: nil
    )

    offer = Offer.last
    submit_order_with_offer_input = { offerId: offer.id.to_s }
    # TODO: question: when is the right step to create a setup intent and transaction?
    expect do
      buyer_client.execute(OfferQueryHelper::SUBMIT_ORDER_WITH_OFFER, input: submit_order_with_offer_input)
    end.to_not change(order.transactions, :count)

    expect(order.reload).to have_attributes(
      state: Order::SUBMITTED,
      fulfillment_type: Order::SHIP,
      items_total_cents: nil,
      shipping_total_cents: nil,
      tax_total_cents: nil,
      buyer_total_cents: nil,
      seller_total_cents: nil,
      commission_fee_cents: nil,
      shipping_country: 'US',
      credit_card_id: 'credit_card_1'
    )
  end

  def seller_counters_with_missing_data_provided
    order = Order.last

    # TODO: feat: partner can counter with artwork location and shipping costs provided. The artwork location will need
    # to be updated in Gravity; shipping costs can be updated in Exchange or both.
    allow_any_instance_of(OfferTotals).to receive_messages(
      shipping_total_cents: 30_00,
      tax_total_cents: 25_00,
      should_remit_sales_tax: false
    )
    allow_any_instance_of(OfferOrderTotals).to receive_messages(
      commission_rate: 0.13,
      commission_fee_cents: 17_00,
      transaction_fee_cents: 19_00
    )
    # `last_offer` is set in `set_order_totals!` that we mocked above. Here we manually update it for now.
    order.update! last_offer: Offer.last
    allow_any_instance_of(OfferProcessor).to receive(:set_order_totals!).and_call_original

    offer = Offer.last
    # seller_counter_offer_input = { offerId: offer.id.to_s, shippingTotalCents: 30_00 }
    seller_counter_offer_input = { offerId: offer.id.to_s, amountCents: 500_00 }
    expect do
      seller_client.execute(OfferQueryHelper::SELLER_COUNTER_OFFER, input: seller_counter_offer_input)
    end.to change(order.offers, :count).by(1)

    expect(order.reload).to have_attributes(
      state: Order::SUBMITTED,
      fulfillment_type: Order::SHIP,
      items_total_cents: 500_00,
      shipping_total_cents: 30_00,
      tax_total_cents: 25_00,
      buyer_total_cents: 555_00,
      commission_fee_cents: 17_00,
      transaction_fee_cents: 19_00,
      seller_total_cents: 519_00,
      shipping_country: 'US',
      credit_card_id: 'credit_card_1'
    )
  end

  def buyer_accepts_offer
    order = Order.last

    # TODO: feat: capture payment and update transactions
    allow_any_instance_of(OrderProcessor).to receive_messages(
      debit_commission_exemption: nil,
      charge: nil,
      store_transaction: nil
    )

    seller_counter_offer = order.offers.order(created_at: :desc).first
    buyer_accept_offer_input = { offerId: seller_counter_offer.id.to_s }
    buyer_client.execute(OfferQueryHelper::BUYER_ACCEPT_OFFER, input: buyer_accept_offer_input)

    expect(order.reload).to have_attributes(
      state: Order::APPROVED,
      fulfillment_type: Order::SHIP,
      items_total_cents: 500_00,
      shipping_total_cents: 30_00,
      tax_total_cents: 25_00,
      buyer_total_cents: 555_00,
      commission_fee_cents: 17_00,
      transaction_fee_cents: 19_00,
      seller_total_cents: 519_00,
      shipping_country: 'US',
      credit_card_id: 'credit_card_1'
    )

    deduct_inventory_request = stub_request(:put, "#{gravity_v1_api_root}/artwork/#{artwork[:_id]}/inventory")
    expect(deduct_inventory_request).to_not have_been_made

    # TODO: test: assert transactions
  end
end
