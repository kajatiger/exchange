require 'rails_helper'

describe Api::GraphqlController, type: :request do
  describe 'set_payment mutation' do
    include_context 'GraphQL Client'
    let(:seller_id) { jwt_partner_ids.first }
    let(:user_id) { jwt_user_id }
    let(:credit_card_id) { 'gravity-cc-1' }
    let(:credit_card) { { id: credit_card_id, user: { _id: user_id } } }
    let(:order) { Fabricate(:order, seller_id: seller_id, buyer_id: user_id) }

    let(:mutation) { <<-GRAPHQL }
        mutation($input: SetPaymentInput!) {
          setPayment(input: $input) {
            orderOrError {
              ... on OrderWithMutationSuccess {
                order {
                  id
                  state
                  creditCardId
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

    let(:set_payment_input) do
      { input: { id: order.id.to_s, creditCardId: credit_card_id } }
    end
    context 'with user without permission to this order' do
      let(:user_id) { 'random-user-id-on-another-order' }
      it 'returns permission error' do
        response = client.execute(mutation, set_payment_input)
        expect(
          response.data.set_payment.order_or_error.error.type
        ).to eq 'validation'
        expect(
          response.data.set_payment.order_or_error.error.code
        ).to eq 'not_found'
        expect(order.reload.state).to eq Order::PENDING
      end
    end

    context 'with proper permission' do
      context 'with order in non-pending state' do
        Order::STATES
          .reject { |s| s == Order::PENDING }
          .each do |state|
            it 'returns error' do
              order.update! state: state,
                            state_reason:
                              state == Order::CANCELED ? 'seller_lapsed' : nil
              response = client.execute(mutation, set_payment_input)
              expect(
                response.data.set_payment.order_or_error.error.type
              ).to eq 'validation'
              expect(
                response.data.set_payment.order_or_error.error.code
              ).to eq 'invalid_state'
              expect(order.reload.state).to eq state
            end
          end
      end

      context 'with an order in pending state' do
        context 'with a credit card that belongs to the buyer' do
          before do
            expect(Gravity).to receive(:get_credit_card)
              .with(credit_card_id)
              .and_return(credit_card)
          end
          it 'sets payments on the order' do
            response = client.execute(mutation, set_payment_input)
            expect(
              response.data.set_payment.order_or_error.order.id
            ).to eq order.id.to_s
            expect(
              response.data.set_payment.order_or_error.order.state
            ).to eq 'PENDING'
            expect(
              response.data.set_payment.order_or_error.order.credit_card_id
            ).to eq 'gravity-cc-1'
            expect(response.data.set_payment.order_or_error).not_to respond_to(
              :error
            )
            expect(order.reload.credit_card_id).to eq credit_card_id
            expect(order.state).to eq Order::PENDING
            expect(order.state_expires_at).to eq(
              order.state_updated_at + 2.days
            )
          end
          context 'with existing external_charge_id on order' do
            it 'clears external_charge_id so we create new payment intent when creating charge nex' do
              order.update!(external_charge_id: 'pi_1')
              client.execute(mutation, set_payment_input)
              expect(order.reload.external_charge_id).to be_nil
            end
          end
        end
        context 'with a credit card that does not belong to the buyer' do
          let(:invalid_credit_card) do
            { id: credit_card_id, user: { _id: 'someone_else' } }
          end
          it 'raises an error' do
            expect(Gravity).to receive(:get_credit_card)
              .with(credit_card_id)
              .and_return(invalid_credit_card)
            response = client.execute(mutation, set_payment_input)
            expect(
              response.data.set_payment.order_or_error.error.type
            ).to eq 'validation'
            expect(
              response.data.set_payment.order_or_error.error.code
            ).to eq 'invalid_credit_card'
            expect(order.reload.credit_card_id).to be_nil
          end
        end
      end
    end
  end
end
