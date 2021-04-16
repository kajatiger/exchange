require 'rails_helper'

describe ARTA do
  describe '.generate_shipment_quotes' do
    context 'success' do
      let(:response) { load_fixtures('./support/fixtures/arta/quote_request_success_response.json') }

      it 'returns the correct response' do
        # TODO: make this test better
        stub_request(:post, "#{Rails.application.config_for(:arta)['arta_api_root_url']}/requests").to_return(status: 201, body: response.to_json)

        expect do
          ARTA.generate_shipment_quotes
        end.to_not raise_error(ARTAError)
      end
    end

    context 'failure' do
      context '422 status code from ARTA' do
        let(:response) { load_fixtures('./support/fixtures/arta/quote_request_unprocessible_entity_failure_response.json') }

        it 'raises an error' do
          stub_request(:post, "#{Rails.application.config_for(:arta)['arta_api_root_url']}/requests").to_return(status: 422, body: response.to_json)

          expect do
            ARTA.generate_shipment_quotes
          end.to raise_error(ARTAError)
        end
      end

      context '500 status code from ARTA' do
        it 'raises an error' do
          stub_request(:post, "#{Rails.application.config_for(:arta)['arta_api_root_url']}/requests").to_return(status: 500, body: {}.to_json)

          expect do
            ARTA.generate_shipment_quotes
          end.to raise_error(ARTAError)
        end
      end
    end
  end
end
