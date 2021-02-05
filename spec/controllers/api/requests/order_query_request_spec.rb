require 'rails_helper'

describe Api::GraphqlController, type: :request do
  describe 'order query' do
    include_context 'GraphQL Client'
    let(:seller_id) { jwt_partner_ids.first }
    let(:second_seller_id) { 'partner-2' }
    let(:user_id) { jwt_user_id }
    let(:second_user) { 'user2' }
    let(:state) { Order::PENDING }
    let(:created_at) { 2.days.ago }
    let(:order_mode) { Order::BUY }
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
        created_at: created_at,
        updated_at: 1.day.ago,
        shipping_total_cents: 100_00,
        commission_fee_cents: 50_00,
        commission_rate: 0.10,
        seller_total_cents: 50_00,
        buyer_total_cents: 100_00,
        items_total_cents: 0,
        state: state,
        state_reason: state == Order::CANCELED ? 'seller_lapsed' : nil,
        impulse_conversation_id: impulse_conversation_id
      )
    end
    let!(:user2_order1) { Fabricate(:order, seller_id: second_seller_id, seller_type: 'gallery', buyer_id: second_user, buyer_type: 'user', items_total_cents: 0) }

    let(:query) do
      <<-GRAPHQL
        query($id: ID, $offerFromId: String, $offerFromType: String) {
          order(id: $id) {
            id
            internalID
            mode
            buyer {
              ... on User {
                id
              }
            }
            seller {
              ... on Partner {
                id
              }
            }
            state
            stateReason
            requestedFulfillment{
              ... on Ship {
                phoneNumber
                addressLine1
                region
                country
                city
              }
              ... on Pickup {
                phoneNumber
              }
            }
            currencyCode
            itemsTotalCents
            shippingTotalCents
            sellerTotalCents
            buyerTotalCents
            createdAt
            lastTransactionFailed
            displayCommissionRate
            ... on OfferOrder {
              impulseConversationId
              awaitingResponseFrom
              lastOffer {
                id
                amountCents
                submittedAt
                respondsTo {
                  id
                }
                from {
                  __typename
                  ... on User {
                    id
                  }
                  ... on Partner {
                    id
                  }
                }
              }

              offers(fromId: $offerFromId, fromType: $offerFromType) {
                edges {
                  node {
                    id
                    amountCents
                    submittedAt
                    from {
                      __typename
                      ... on User {
                        id
                      }
                      ... on Partner {
                        id
                      }
                    }
                  }
                }
              }
            }
            lineItems {
              edges {
                node {
                  id
                  priceCents
                  artworkId
                  editionSetId
                }
              }
            }
          }
        }
      GRAPHQL
    end

    let(:query_by_code) do
      <<-GRAPHQL
        query($code: String) {
          order(code: $code) {
            id
            buyer {
              ... on User {
                id
              }
            }
            seller {
              ... on Partner {
                id
              }
            }
            requestedFulfillment{
              ... on Ship {
                phoneNumber
                addressLine1
                region
                country
                city
              }
              ... on Pickup {
                phoneNumber
              }
            }
            state
            stateReason
            currencyCode
            itemsTotalCents
            shippingTotalCents
            sellerTotalCents
            buyerTotalCents
            lastTransactionFailed
            createdAt
            ... on OfferOrder {
              lastOffer {
                id
                amountCents
                submittedAt
                respondsTo {
                  id
                }
                from {
                  __typename
                  ... on User {
                    id
                  }
                  ... on Partner {
                    id
                  }
                }
              }
              offers {
                edges {
                  node {
                    id
                    amountCents
                    submittedAt
                  }
                }
              }
            }
            lineItems {
              edges {
                node {
                  id
                  priceCents
                }
              }
            }
          }
        }
      GRAPHQL
    end

    context 'user accessing their order' do
      it 'returns not found error when query for orders by user not in jwt' do
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

      it 'returns order when accessing correct order' do
        result = client.execute(query, id: user1_order1.id)
        expect(result.data.order.mode).to eq 'BUY'
        expect(result.data.order.buyer.id).to eq user_id
        expect(result.data.order.seller.id).to eq seller_id
        expect(result.data.order.currency_code).to eq 'USD'
        expect(result.data.order.state).to eq 'PENDING'
        expect(result.data.order.items_total_cents).to eq 0
        expect(result.data.order.seller_total_cents).to eq 50_00
        expect(result.data.order.buyer_total_cents).to eq 100_00
        expect(result.data.order.created_at).to eq created_at.iso8601
        expect(result.data.order.last_transaction_failed).to eq false
      end

      it 'returns order when accessing correct order by code' do
        result = client.execute(query_by_code, code: user1_order1.code)
        expect(result.data.order.buyer.id).to eq user_id
        expect(result.data.order.seller.id).to eq seller_id
        expect(result.data.order.currency_code).to eq 'USD'
        expect(result.data.order.state).to eq 'PENDING'
        expect(result.data.order.items_total_cents).to eq 0
        expect(result.data.order.seller_total_cents).to eq 50_00
        expect(result.data.order.buyer_total_cents).to eq 100_00
        expect(result.data.order.created_at).to eq created_at.iso8601
      end

      it 'formats commission_rate into a display string' do
        result = client.execute(query, id: user1_order1.id)
        expect(result.data.order.display_commission_rate).to eq '10%'
      end

      context 'with line items' do
        let!(:order1_line_item1) { Fabricate(:line_item, order: user1_order1, artwork_id: 'artwork1', edition_set_id: 'edi-1') }
        let!(:order1_line_item2) { Fabricate(:line_item, order: user1_order1, artwork_id: 'artwork2', edition_set_id: 'edi-2') }

        it 'includes line items' do
          result = client.execute(query, id: user1_order1.id)
          expect(result.data.order.line_items.edges.count).to eq 2
          expect(result.data.order.line_items.edges.map(&:node).map(&:id)).to match_array [order1_line_item1.id, order1_line_item2.id]
          expect(result.data.order.line_items.edges.map(&:node).map(&:artwork_id)).to match_array %w[artwork1 artwork2]
          expect(result.data.order.line_items.edges.map(&:node).map(&:edition_set_id)).to match_array %w[edi-1 edi-2]
        end
      end

      context 'with offers' do
        let(:state) { Order::SUBMITTED }
        let(:order_mode) { Order::OFFER }
        let!(:buyer_offer) { Fabricate(:offer, order: user1_order1, amount_cents: 200, from_id: user_id, from_type: Order::USER, submitted_at: Date.new(2018, 1, 1)) }
        let!(:seller_offer) { Fabricate(:offer, order: user1_order1, amount_cents: 300, from_id: seller_id, from_type: 'gallery', responds_to_id: buyer_offer.id, submitted_at: Date.new(2018, 1, 2)) }
        let!(:pending_buyer_offer) { Fabricate(:offer, order: user1_order1, amount_cents: 200, from_id: user_id, from_type: Order::USER) }

        before do
          user1_order1.update! last_offer: seller_offer
        end

        describe 'the query result' do
          let(:result) { client.execute(query, id: user1_order1.id) }

          it 'excludes pending offers' do
            expect(result.data.order.offers.edges.count).to eq 2
            expect(result.data.order.offers.edges.map(&:node).map(&:id)).to match_array [buyer_offer.id, seller_offer.id]
            expect(result.data.order.offers.edges.map(&:node).map(&:amount_cents)).to match_array [200, 300]
            expect(result.data.order.offers.edges.map(&:node).map(&:from).map(&:id)).to match_array [user_id, seller_id]
            expect(result.data.order.offers.edges.map(&:node).map(&:from).map(&:__typename)).to match_array %w[User Partner]
            expect(result.data.order.offers.edges.first.node.submitted_at).to eq '2018-01-02T00:00:00Z'
          end

          it 'includes last_offer' do
            expect(result.data.order.last_offer.id).to eq seller_offer.id
            expect(result.data.order.last_offer.from.id).to eq seller_id
            expect(result.data.order.last_offer.from.__typename).to eq 'Partner'
            expect(result.data.order.last_offer.responds_to.id).to eq buyer_offer.id
          end

          it 'includes last_transaction_failed' do
            expect(result.data.order.last_transaction_failed).to eq false
          end
        end

        describe 'awaiting_response_from' do
          [Order::APPROVED, Order::PENDING, Order::FULFILLED, Order::REFUNDED, Order::ABANDONED].each do |state|
            context "Order in #{state} state" do
              let(:state) { state }

              it 'returns nil' do
                result = client.execute(query, id: user1_order1.id)
                expect(result.data.order.awaiting_response_from).to be_nil
              end
            end
          end

          context 'without lastOffer' do
            it 'returns nil' do
              user1_order1.update!(last_offer: nil)
              result = client.execute(query, id: user1_order1.id)
              expect(result.data.order.awaiting_response_from).to be_nil
            end
          end

          context 'last offer from seller' do
            it 'returns BUYER for awaitingResponseFrom' do
              result = client.execute(query, id: user1_order1.id)
              expect(result.data.order.awaiting_response_from).to eq 'BUYER'
            end
          end

          context 'last offer from buyer' do
            before do
              user1_order1.update! last_offer: buyer_offer
            end

            it 'returns BUYER for awaitingResponseFrom' do
              result = client.execute(query, id: user1_order1.id)
              expect(result.data.order.awaiting_response_from).to eq 'SELLER'
            end
          end
        end

        describe 'offer filters' do
          it 'filters by from id' do
            result = client.execute(query, id: user1_order1.id, offerFromId: user_id)
            expect(result.data.order.offers.edges.count).to eq 1
            expect(result.data.order.offers.edges.map(&:node).map(&:id)).to eq [buyer_offer.id]
            expect(result.data.order.offers.edges.map(&:node).map(&:amount_cents)).to eq [200]
            expect(result.data.order.offers.edges.map(&:node).map(&:from).map(&:id)).to eq [user_id]
            expect(result.data.order.offers.edges.map(&:node).map(&:from).map(&:__typename)).to eq %w[User]
          end

          it 'filters by from type' do
            result = client.execute(query, id: user1_order1.id, offerFromType: 'gallery')
            expect(result.data.order.offers.edges.count).to eq 1
            expect(result.data.order.offers.edges.map(&:node).map(&:id)).to eq [seller_offer.id]
            expect(result.data.order.offers.edges.map(&:node).map(&:amount_cents)).to eq [300]
            expect(result.data.order.offers.edges.map(&:node).map(&:from).map(&:id)).to eq [seller_id]
            expect(result.data.order.offers.edges.map(&:node).map(&:from).map(&:__typename)).to eq %w[Partner]
          end
        end

        describe 'offer from conversation' do
          let(:impulse_conversation_id) { '123456' }
          let(:result) { client.execute(query, id: user1_order1.id) }

          it 'includes last_transaction_failed' do
            expect(result.data.order.impulse_conversation_id).to eq '123456'
          end
        end
      end

      Order::STATES.each do |state|
        # https://github.com/artsy/exchange/issues/88
        context "order in #{state} state" do
          let(:state) { state }
          it 'returns proper state' do
            result = client.execute(query, id: user1_order1.id)
            expect(result.data.order.state).to eq state.upcase
          end
        end
      end

      context 'when state is CANCELED' do
        let(:state) { Order::CANCELED }
        it 'returns state_reason' do
          result = client.execute(query, id: user1_order1.id)
          expect(result.data.order.state_reason).to eq 'seller_lapsed'
        end
      end

      context 'when pickup' do
        let(:fulfillment_type) { Order::PICKUP }
        it 'returns proper pickup information' do
          user1_order1.update!(buyer_phone_number: '6178339999')
          result = client.execute(query, id: user1_order1.id)
          expect(result.data.order.requested_fulfillment).to have_attributes(
            phone_number: '6178339999'
          )
        end
      end

      context 'when ship' do
        it 'returns proper shipping information' do
          user1_order1.update!(buyer_phone_number: '6178339999', shipping_address_line1: '123 Random St', shipping_region: 'NY', shipping_city: 'Brooklyn', shipping_country: 'Absurdistan')
          result = client.execute(query, id: user1_order1.id)
          expect(result.data.order.requested_fulfillment).to have_attributes(
            phone_number: '6178339999',
            address_line1: '123 Random St',
            region: 'NY',
            city: 'Brooklyn',
            country: 'Absurdistan'
          )
        end
      end
    end

    context 'trusted user rules' do
      let(:jwt_user_id) { 'rando' }

      context "trusted account accessing another account's order" do
        let(:jwt_roles) { 'trusted' }

        it 'allows action' do
          expect do
            client.execute(query, id: user2_order1.id)
          end.to_not raise_error
        end

        it 'returns expected payload' do
          result = client.execute(query, id: user2_order1.id)
          expect(result.data.order.internal_id).to eq user2_order1.id
          expect(result.data.order.buyer.id).to eq user2_order1.buyer_id
          expect(result.data.order.seller.id).to eq user2_order1.seller_id
          expect(result.data.order.currency_code).to eq 'USD'
          expect(result.data.order.state).to eq 'PENDING'
          expect(result.data.order.items_total_cents).to eq 0
        end

        it 'cannot access seller_only fields' do
          # TODO: we may want to change this logic later but for now not allowing
          # those fields for trusted apps
          result = client.execute(query, id: user2_order1.id)
          expect(result.data.order.seller_total_cents).to be_nil
        end
      end

      context 'untrusted account accessing another account\'s order' do
        let(:jwt_roles) { 'foobar' }

        it 'raises error' do
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

      context 'normal admin accessing an order' do
        let(:jwt_roles) { 'admin' }

        it 'raises error' do
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

      context "sales admin accessing another account's order" do
        let(:jwt_roles) { 'admin,sales_admin' }

        it 'allows action' do
          expect do
            client.execute(query, id: user2_order1.id)
          end.to_not raise_error
        end

        it 'returns expected payload' do
          result = client.execute(query, id: user2_order1.id)
          expect(result.data.order.buyer.id).to eq user2_order1.buyer_id
          expect(result.data.order.seller.id).to eq user2_order1.seller_id
          expect(result.data.order.currency_code).to eq 'USD'
          expect(result.data.order.state).to eq 'PENDING'
          expect(result.data.order.items_total_cents).to eq 0
        end
      end

      context "liaison accessing another account's order" do
        let(:jwt_roles) { 'partner_support' }

        it 'allows action' do
          expect do
            client.execute(query, id: user2_order1.id)
          end.to_not raise_error
        end

        it 'returns expected payload' do
          result = client.execute(query, id: user2_order1.id)
          expect(result.data.order.buyer.id).to eq user2_order1.buyer_id
          expect(result.data.order.seller.id).to eq user2_order1.seller_id
          expect(result.data.order.currency_code).to eq 'USD'
          expect(result.data.order.state).to eq 'PENDING'
          expect(result.data.order.items_total_cents).to eq 0
        end
      end
    end

    context 'partner accessing order' do
      it 'returns order when accessing correct order' do
        another_user_order = Fabricate(:order, seller_id: seller_id, buyer_id: 'someone-else-id')
        result = client.execute(query, id: another_user_order.id)
        expect(result.data.order.buyer.id).to eq 'someone-else-id'
        expect(result.data.order.seller.id).to eq seller_id
        expect(result.data.order.currency_code).to eq 'USD'
        expect(result.data.order.state).to eq 'PENDING'
        expect(result.data.order.items_total_cents).to be_nil
      end
    end
  end
end
