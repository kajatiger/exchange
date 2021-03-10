require 'rails_helper'

describe Api::GraphqlController, type: :request do
  describe 'query for order history' do
    include_context 'GraphQL Client'

    let(:seller_id) { jwt_partner_ids.first }
    let(:user_id) { jwt_user_id }
    let(:order_mode) { Order::OFFER }
    let(:fulfillment_type) { Order::SHIP }
    let(:impulse_conversation_id) { nil }
    let!(:user1_order1) do
      Fabricate(
        :order,
        mode: order_mode,
        fulfillment_type: fulfillment_type,
        seller_id: seller_id,
        seller_type: 'gallery',
        buyer_id: user_id,
        buyer_type: 'user',
        updated_at: 1.day.ago,
        shipping_total_cents: 100_00,
        commission_fee_cents: 50_00,
        commission_rate: 0.10,
        seller_total_cents: 50_00,
        buyer_total_cents: 100_00,
        items_total_cents: 0,
        state: Order::PENDING,
        state_reason: nil,
        impulse_conversation_id: impulse_conversation_id
      )
    end
    let(:user2_order1) { Fabricate(:order) }

    let(:query) do
      <<-GRAPHQL
        query($id: ID) {
          order(id: $id) {
            orderHistory {
              __typename
              ... on OfferSubmittedEvent {
                createdAt
                offer {
                  amountCents
                  fromParticipant
                }
              }
              ... on OrderStateChangedEvent {
                createdAt
                state
                stateReason
              }
            }
          }
        }
      GRAPHQL
    end

    before { Timecop.freeze }
    after { Timecop.return }

    context 'orders by user not in jwt' do
      it 'returns not found error when query for ' do
        expect do
          client.execute(query, id: user2_order1.id)
        end.to raise_error do |error|
          expect(error).to be_a(Graphlient::Errors::ServerError)
          expect(error.message).to eq 'the server responded with status 404'
          expect(error.status_code).to eq 404
          expect(error.response['errors'].first['extensions']['code']).to eq 'not_found'
          expect(error.response['errors'].first['extensions']['type']).to eq 'validation'
        end
      end
    end

    context 'buy order' do
      let(:order_mode) { Order::BUY }
      before do
        Timecop.travel(1.minute)
        user1_order1.submit!
      end
      it 'contains the events' do
        result = client.execute(query, id: user1_order1.id)
        events = result.data.order.order_history

        expect(events.length).to be(2)

        expect(events[0].__typename).to eq 'OrderStateChangedEvent'
        expect(events[0].state).to eq 'PENDING'

        expect(events[1].__typename).to eq 'OrderStateChangedEvent'
        expect(events[1].state).to eq 'SUBMITTED'
      end
    end

    context 'offer order' do
      before do
        Timecop.travel(1.minute)
        user1_order1.submit!
        Timecop.travel(1.minute)
        user1_order1.offers.create!(amount_cents: 200, from_id: user_id, from_type: Order::USER, submitted_at: Time.now.utc)
        Timecop.travel(1.minute)
        user1_order1.offers.create!(amount_cents: 300, from_id: seller_id, from_type: user1_order1.seller_type, submitted_at: Time.now.utc)
        Timecop.travel(1.minute)
        last_offer = user1_order1.offers.create!(amount_cents: 250, from_id: user_id, from_type: Order::USER, submitted_at: Time.now.utc)
        user1_order1.update! last_offer: last_offer
      end

      describe 'the query result' do
        it 'contains the events' do
          result = client.execute(query, id: user1_order1.id)
          events = result.data.order.order_history

          expect(events.length).to be(5)

          expect(events[0].__typename).to eq 'OrderStateChangedEvent'
          expect(events[0].state).to eq 'PENDING'

          expect(events[1].__typename).to eq 'OrderStateChangedEvent'
          expect(events[1].state).to eq 'SUBMITTED'

          expect(events[2].__typename).to eq 'OfferSubmittedEvent'
          expect(events[2].offer.amount_cents).to eq 200
          expect(events[2].offer.from_participant).to eq 'BUYER'

          expect(events[3].__typename).to eq 'OfferSubmittedEvent'
          expect(events[3].offer.amount_cents).to eq 300
          expect(events[3].offer.from_participant).to eq 'SELLER'

          expect(events[4].__typename).to eq 'OfferSubmittedEvent'
          expect(events[4].offer.amount_cents).to eq 250
          expect(events[4].offer.from_participant).to eq 'BUYER'
        end
      end
    end
  end
end
