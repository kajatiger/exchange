require 'rails_helper'
require 'support/gravity_helper'

describe OfferProcessor, type: :services do
  include_context 'include stripe helper'

  let(:order) { Fabricate(:order, seller_id: 'partner_1', seller_type: 'gallery', buyer_id: 'user_1', buyer_type: 'user', state: Order::PENDING, mode: Order::OFFER) }
  let(:offer) { Fabricate(:offer, from_id: 'user_1', from_type: 'user', amount_cents: 200, order: order) }
  let(:op) { OfferProcessor.new(offer) }

  describe '#validate_offer!' do
    it 'raises error when offer already submitted' do
      offer.update!(submitted_at: Time.now.utc)
      expect { op.validate_offer! }.to raise_error(Errors::ValidationError)
    end

    it 'does not raise error when order is not submitted' do
      expect { op.validate_offer! }.not_to raise_error
    end
  end

  describe '#check_inventory!' do
    context 'with inventory' do
      it 'does not raise error' do
        allow(order).to receive(:inventory?).and_return(true)
        expect { op.check_inventory! }.not_to raise_error
      end
    end

    context 'without inventory' do
      it 'raises error' do
        allow(order).to receive(:inventory?).and_return(false)
        expect { op.check_inventory! }.to raise_error(Errors::InsufficientInventoryError)
      end

      it 'does not raise error for inquiry orders' do
        order.impulse_conversation_id = '401'
        allow(order).to receive(:inventory?).and_return(false)
        expect { op.check_inventory! }.not_to raise_error
      end
    end
  end

  describe '#validate_order!' do
    it 'raises error when its a buy order' do
      order.update!(mode: Order::BUY)
      expect { op.validate_order! }.to raise_error(Errors::ValidationError)
    end

    it 'raises error when order not committable' do
      allow(order).to receive(:can_commit?).and_return(false)
      expect { op.validate_order! }.to raise_error(Errors::ValidationError)
    end

    it 'raises error when invalid artwork version' do
      allow(order).to receive(:valid_artwork_version?).and_return(false)
      expect { op.validate_order! }.to raise_error(Errors::ValidationError)
    end

    it 'raises error when invalid credit card' do
      allow(order).to receive(:assert_credit_card).and_return(:credit_card_missing_external_id)
      expect { op.validate_order! }.to raise_error(Errors::ValidationError)
    end

    it 'does not raise error Oif all good and sunny' do
      allow(order).to receive_messages(
        can_commit?: true,
        valid_artwork_version?: true,
        assert_credit_card: nil
      )
      expect { op.validate_order! }.not_to raise_error
    end
  end

  describe '#submit_order!' do
    it 'submits the order' do
      op.submit_order!
      expect(order.reload.state).to eq Order::SUBMITTED
    end
  end

  describe '#confirm_payment_method!' do
    context 'without sending setup_intent_id' do
      it 'adds transaction to the order in case of success' do
        transaction = Fabricate(:transaction, status: Transaction::SUCCESS)
        expect(PaymentMethodService).to receive(:confirm_payment_method!).with(order).and_return(transaction)
        expect { op.confirm_payment_method! }.to change(order.transactions, :count).by(1)
        expect(order.transactions.first.id).to eq transaction.id
      end

      it 'adds transaction to the order and raises error in case of require action' do
        transaction = Fabricate(:transaction, status: Transaction::REQUIRES_ACTION, payload: { client_secret: 'si_test1' })
        expect(PaymentMethodService).to receive(:confirm_payment_method!).with(order).and_return(transaction)
        expect { op.confirm_payment_method! }.to raise_error(Errors::PaymentRequiresActionError).and change(order.transactions, :count).by(1)
        expect(order.transactions.first.id).to eq transaction.id
      end
    end

    context 'verifying existing setup intent' do
      it 'adds transaction to the order in case of success' do
        prepare_setup_intent_retrieve
        expect { op.confirm_payment_method!('si_1') }.to change(order.transactions, :count).by(1)
        expect(order.transactions.first).to have_attributes(external_id: 'si_1', external_type: Transaction::SETUP_INTENT, transaction_type: Transaction::CONFIRM, status: Transaction::SUCCESS)
      end

      it 'adds transaction to the order and raises error in case of require action' do
        prepare_setup_intent_retrieve(status: 'requires_action')
        expect { op.confirm_payment_method!('si_1') }.to raise_error(Errors::PaymentRequiresActionError).and change(order.transactions, :count).by(1)
        expect(order.transactions.first).to have_attributes(external_id: 'si_1', external_type: Transaction::SETUP_INTENT, transaction_type: Transaction::CONFIRM, status: Transaction::REQUIRES_ACTION)
      end
    end

    context 'setup intent fails with card_decline' do
      it 'adds transaction to the order and raises error in case of require action' do
        transaction = Fabricate(:transaction, status: Transaction::FAILURE, external_id: 'si_1', external_type: Transaction::SETUP_INTENT, transaction_type: Transaction::CONFIRM)
        expect(PaymentMethodService).to receive(:confirm_payment_method!).with(order).and_return(transaction)
        expect { op.confirm_payment_method! }.to raise_error(Errors::FailedTransactionError).and change(order.transactions, :count).by(1)
        expect(order.transactions.first).to have_attributes(external_id: 'si_1', external_type: Transaction::SETUP_INTENT, transaction_type: Transaction::CONFIRM, status: Transaction::FAILURE)
      end
    end
  end

  describe '#update_offer_submission_timestamp' do
    it 'updates offers submitted at' do
      op.update_offer_submission_timestamp
      expect(offer.reload.submitted_at).not_to be_nil
    end
  end

  describe '#on_success!' do
    before do
      order.update!(state: Order::SUBMITTED)
      op.on_success
    end
    it 'queues OrderFollowUpJob' do
      expect(OrderFollowUpJob).to have_been_enqueued.with(order.id, Order::SUBMITTED)
    end

    it 'queues OfferRespondReminderJob' do
      expect(OfferRespondReminderJob).to have_been_enqueued.with(order.id, offer.id)
    end

    it 'posts offer event' do
      expect(PostEventJob).to have_been_enqueued
    end
  end

  describe '#order_on_success' do
    it 'posts order event' do
      op.order_on_success
      expect(PostEventJob).to have_been_enqueued
    end
  end
end
