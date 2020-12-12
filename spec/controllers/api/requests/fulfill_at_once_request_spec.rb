require 'rails_helper'

describe Api::GraphqlController, type: :request do
  describe 'fulfill_at_once mutation' do
    include_context 'GraphQL Client'
    let(:seller_id) { jwt_partner_ids.first }
    let(:user_id) { jwt_user_id }
    let(:credit_card_id) { 'cc-1' }
    let(:order) { Fabricate(:order, seller_id: seller_id, buyer_id: user_id) }
    let!(:line_items) do
      Array.new(2) do
        Fabricate(:line_item, order: order, list_price_cents: 200)
      end
    end

    let(:fulfill_at_once_input) do
      {
        input: {
          id: order.id.to_s,
          fulfillment: {
            courier: 'FedEx',
            trackingId: 'fedx-123',
            estimatedDelivery: '2018-12-15'
          }
        }
      }
    end
    context 'with user without permission to this partner' do
      let(:seller_id) { 'another-partner-id' }
      it 'returns permission error' do
        response =
          client.execute(QueryHelper::FULFILL_ORDER, fulfill_at_once_input)
        expect(
          response.data.fulfill_at_once.order_or_error.error.type
        ).to eq 'validation'
        expect(
          response.data.fulfill_at_once.order_or_error.error.code
        ).to eq 'not_found'
        expect(order.reload.state).to eq Order::PENDING
      end
    end

    context 'with order not in approved state' do
      before { order.update! state: Order::SUBMITTED }
      it 'returns error' do
        response =
          client.execute(QueryHelper::FULFILL_ORDER, fulfill_at_once_input)
        expect(
          response.data.fulfill_at_once.order_or_error.error.type
        ).to eq 'validation'
        expect(
          response.data.fulfill_at_once.order_or_error.error.code
        ).to eq 'invalid_state'
        expect(order.reload.state).to eq Order::SUBMITTED
      end
    end

    context 'with proper permission' do
      before { order.update! state: Order::APPROVED }
      it 'fulfills the order' do
        expect do
          response =
            client.execute(QueryHelper::FULFILL_ORDER, fulfill_at_once_input)
          expect(
            response.data.fulfill_at_once.order_or_error.order.id
          ).to eq order.id.to_s
          expect(
            response.data.fulfill_at_once.order_or_error.order.state
          ).to eq 'FULFILLED'
          response
            .data
            .fulfill_at_once
            .order_or_error
            .order
            .line_items
            .edges
            .each do |li|
              li
                .node
                .fulfillments
                .edges
                .each do |f|
                  expect(f.node.courier).to eq 'FedEx'
                  expect(f.node.tracking_id).to eq 'fedx-123'
                  expect(f.node.estimated_delivery).to eq '2018-12-15'
                end
            end
          expect(
            response.data.fulfill_at_once.order_or_error
          ).not_to respond_to(:error)
          expect(order.reload.state).to eq Order::FULFILLED
          order.line_items.each do |li|
            expect(li.fulfillments.count).to eq 1
            expect(li.fulfillments.first).to have_attributes(
              courier: 'FedEx',
              tracking_id: 'fedx-123',
              estimated_delivery: Date.strptime('2018-12-15', '%Y-%m-%d')
            )
          end
        end.to change(Fulfillment, :count).by(1).and change(
                                               LineItemFulfillment,
                                               :count
                                             ).by(2)
      end
    end
  end
end
