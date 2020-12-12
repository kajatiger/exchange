require 'rails_helper'

describe Api::GraphqlController, type: :request do
  include_context 'include stripe helper'

  describe 'reject_order mutation' do
    include_context 'GraphQL Client'
    let(:seller_id) { jwt_partner_ids.first }
    let(:user_id) { jwt_user_id }
    let(:credit_card_id) { 'cc-1' }
    let(:order) do
      Fabricate(
        :order,
        seller_id: seller_id,
        buyer_id: user_id,
        external_charge_id: 'pi_1'
      )
    end

    let(:mutation) { <<-GRAPHQL }
        mutation($input: RejectOrderInput!) {
          rejectOrder(input: $input) {
            orderOrError {
              ... on OrderWithMutationSuccess {
                order {
                  id
                  state
                  buyer {
                    ... on Partner {
                      id
                    }
                  }
                  seller {
                    ... on User {
                      id
                    }
                  }
                }
              }
              ... on OrderWithMutationFailure {
                error {
                  code
                  data
                  type
                }
              }
            }
          }
        }
      GRAPHQL

    let(:reject_order_input) { { input: { id: order.id.to_s } } }
    context 'with user without permission to this partner' do
      let(:seller_id) { 'another-partner-id' }
      it 'returns permission error' do
        response = client.execute(mutation, reject_order_input)
        expect(
          response.data.reject_order.order_or_error.error.type
        ).to eq 'validation'
        expect(
          response.data.reject_order.order_or_error.error.code
        ).to eq 'not_found'
        expect(order.reload.state).to eq Order::PENDING
      end
    end

    context 'with order not in submitted state' do
      before { order.update! state: Order::PENDING }
      it 'returns error' do
        response = client.execute(mutation, reject_order_input)
        expect(
          response.data.reject_order.order_or_error.error.type
        ).to eq 'validation'
        expect(
          response.data.reject_order.order_or_error.error.code
        ).to eq 'invalid_state'
        expect(order.reload.state).to eq Order::PENDING
      end
    end

    context 'with proper permission' do
      before do
        Fabricate(
          :transaction,
          order: order,
          external_id: 'pi_1',
          external_type: Transaction::PAYMENT_INTENT
        )
        order.update! state: Order::SUBMITTED
      end
      it 'rejects the order' do
        prepare_payment_intent_cancel_success
        response = client.execute(mutation, reject_order_input)
        expect(response.data.reject_order.order_or_error.order.id).to eq order
             .id.to_s
        expect(
          response.data.reject_order.order_or_error.order.state
        ).to eq 'CANCELED'
        expect(response.data.reject_order.order_or_error).not_to respond_to(
          :error
        )
        expect(order.reload.state).to eq Order::CANCELED
        transaction = order.transactions.order(created_at: :desc).first
        expect(transaction).to have_attributes(
          external_id: 'pi_1',
          external_type: Transaction::PAYMENT_INTENT,
          transaction_type: Transaction::CANCEL
        )
      end
    end
  end
end
