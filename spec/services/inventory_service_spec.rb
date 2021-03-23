require 'rails_helper'

describe InventoryService do
  let(:artwork1_inventory) { { count: 1, unlimited: false } }
  let(:artwork1) { gravity_v1_artwork(_id: 'artwork-1', current_version_id: 'artwork-version-1', inventory: artwork1_inventory) }
  let(:artwork2) { gravity_v1_artwork(_id: 'artwork-1', current_version_id: 'artwork-version-1', inventory: { count: 2, unlimited: false }) }

  let(:order) do
    Fabricate(
      :order,
      mode: Order::BUY,
      buyer_id: 'buyer-1',
      fulfillment_type: Order::SHIP,
      credit_card_id: 'cc-1',
      seller_id: 'seller-1',
      shipping_name: 'Fname Lname',
      shipping_address_line1: '12 Vanak St',
      shipping_address_line2: 'P 80',
      shipping_city: 'Tehran',
      shipping_postal_code: '02198',
      buyer_phone_number: '00123456',
      shipping_country: 'IR',
      items_total_cents: 3000_00
    )
  end
  let(:line_item1) { Fabricate(:line_item, order: order, quantity: 1, list_price_cents: 1000_00, artwork_id: artwork1[:_id], artwork_version_id: artwork1[:current_version_id], sales_tax_cents: 0, shipping_total_cents: 0) }
  let(:line_item2) { Fabricate(:line_item, order: order, quantity: 2, list_price_cents: 1000_00, artwork_id: artwork2[:_id], artwork_version_id: artwork2[:current_version_id], sales_tax_cents: 0, shipping_total_cents: 0) }

  let(:get_artwork1_request) { stub_request(:get, "#{gravity_v1_api_root}/artwork/#{artwork1[:_id]}").to_return(status: 200, body: artwork1.to_json) }
  let(:get_artwork2_request) { stub_request(:get, "#{gravity_v1_api_root}/artwork/#{artwork2[:_id]}").to_return(status: 200, body: artwork2.to_json) }

  let(:deduct_artwork1_inventory_request) { stub_request(:put, "#{gravity_v1_api_root}/artwork/#{artwork1[:_id]}/inventory").with(body: { deduct: 1 }) }
  let(:deduct_artwork2_inventory_request) { stub_request(:put, "#{gravity_v1_api_root}/artwork/#{artwork2[:_id]}/inventory").with(body: { deduct: 2 }) }
  let(:undeduct_artwork1_inventory_request) { stub_request(:put, "#{gravity_v1_api_root}/artwork/#{artwork1[:_id]}/inventory").with(body: { undeduct: 1 }) }
  let(:undeduct_artwork2_inventory_request) { stub_request(:put, "#{gravity_v1_api_root}/artwork/#{artwork1[:_id]}/inventory").with(body: { undeduct: 2 }) }

  let(:service) { InventoryService.new(order) }

  before do
    line_item1
    line_item2
    get_artwork1_request
  end

  describe '#check_inventory' do
    context 'with null inventory' do
      let(:artwork1_inventory) { nil }

      it 'raises an exception' do
        expect do
          service.check_inventory!
        end.to raise_error(Errors::InsufficientInventoryError)
      end
    end

    context 'with insufficient inventory' do
      let(:artwork1_inventory) { { count: 0, unlimited: false } }

      it 'raises an exception' do
        expect do
          service.check_inventory!
        end.to raise_error(Errors::InsufficientInventoryError)
      end
    end

    context 'with sufficient inventory' do
      it 'does not raise an exception with sufficient inventory' do
        expect do
          service.check_inventory!
        end.to_not raise_error
      end
    end
  end

  describe '#deduct_inventory!' do
    context 'on success' do
      before do
        deduct_artwork1_inventory_request.to_return(status: 200, body: {}.to_json)
        deduct_artwork2_inventory_request.to_return(status: 200, body: {}.to_json)

        service.deduct_inventory!
      end

      it 'deducts inventory for all line items of the order' do
        expect(deduct_artwork1_inventory_request).to have_been_made
        expect(deduct_artwork2_inventory_request).to have_been_made
      end

      it 'pushes deducted items in a queue' do
        expect(service.instance_variable_get(:@deducted_items)).to eq [line_item1, line_item2]
      end
    end

    context 'on failure' do
      before do
        deduct_artwork1_inventory_request.to_return(status: 200, body: {}.to_json)
        deduct_artwork2_inventory_request.to_return(status: 400, body: {}.to_json)
      end

      it 'raises an exception' do
        expect do
          service.deduct_inventory!
        end.to raise_error(Errors::InsufficientInventoryError)

        expect(deduct_artwork1_inventory_request).to have_been_made
        expect(deduct_artwork2_inventory_request).to have_been_made
      end

      it 'pushes deducted items in a queue' do
        expect do
          service.deduct_inventory!
        end.to raise_error(Errors::InsufficientInventoryError)

        expect(service.instance_variable_get(:@deducted_items)).to eq [line_item1]
      end
    end
  end

  describe '#undeduct_inventory!' do
    before do
      service.instance_variable_set(:@deducted_items, [line_item1, line_item2])
    end

    context 'on success' do
      before do
        undeduct_artwork1_inventory_request.to_return(status: 200, body: {}.to_json)
        undeduct_artwork2_inventory_request.to_return(status: 200, body: {}.to_json)

        service.undeduct_inventory!
      end

      it 'undeducts inventory for all line items deducted' do
        expect(undeduct_artwork1_inventory_request).to have_been_made
        expect(undeduct_artwork2_inventory_request).to have_been_made
      end

      it 'removes undeducted items from the queue' do
        expect(service.instance_variable_get(:@deducted_items)).to be_empty
      end
    end

    context 'on failure' do
      before do
        undeduct_artwork1_inventory_request.to_return(status: 200, body: {}.to_json)
        undeduct_artwork2_inventory_request.to_return(status: 400, body: {}.to_json)
      end

      it 'raises an exception' do
        expect do
          service.undeduct_inventory!
        end.to raise_error(Errors::ProcessingError, 'undeduct_inventory_failure')

        expect(undeduct_artwork1_inventory_request).to have_been_made
        expect(undeduct_artwork2_inventory_request).to have_been_made
      end

      it 'keeps line items not yet undeducted in the queue' do
        expect do
          service.undeduct_inventory!
        end.to raise_error(Errors::ProcessingError, 'undeduct_inventory_failure')

        expect(service.instance_variable_get(:@deducted_items)).to eq [line_item2]
      end
    end
  end
end
