# frozen_string_literal: true

class ARTAError < StandardError; end

class ARTA
  # Ramblings: thinking this class is just for API calls
  # Build another service class to actually format/prep artsy data for ARTA requests

  # module?
  class << self
    def generate_shipment_quotes(params: {})
      response = connection.post('/requests', params.to_json)

      process(response)
    end

    private

    def process(response)
      # TODO: We should def handle 500s from ARTA here
      # eg: unhandled exception: status: 500, body: {}

      # TODO: 422s that have an error message maybe bubble them up somewhere
      # eg: {:errors=>{:"objects/0"=>["Required property height was not present."]}}
      raise ARTAError, "Couldn't perform request! status: #{response.status}. Message: #{response.body[:errors]}" unless response.success?

      response.body
    end

    def headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => "ARTA_APIKey #{Rails.application.config_for(:arta)['arta_api_key']}"
      }
    end

    def connection
      Faraday.new(
        Rails.application.config_for(:arta)['arta_api_root_url'],
        request: { timeout: 5, open_timeout: 5 },
        headers: headers
      ) do |conn|
        conn.response(:json, parser_options: { symbolize_names: true })
      end
    end
  end
end

#########################################
#########################################
# Use data below to test quote generation in your local console!
# (call ARTA.generate_shipment_quotes(params: params))
=begin

buyer_info = {
  title: "Collector Molly",
  address_line_1: "332 Prospect St",
  city: "Niagara Falls",
  region: "NY",
  country: "US",
  postal_code: "14303",
  contacts: [
    {
      name: "Collector Molly", 
      email_address: "test@email.com",
      phone_number: "4517777777"
    }
  ]
} 

physical_artwork_info = {
  subtype: 'sculpture',
  unit_of_measurement: "cm",
  width: 16.8,
  height: 32.2,
  depth: 12.2,
  value: 400.00,
  value_currency: "USD",
}

artwork_origin_location_and_contact_info = {
  title: "Hello Gallery",
  address_line_1: "401 Broadway",
  city: "New York",
  region: "NY",
  country: "US",
  postal_code: "10013",
  contacts: [
    {
      name: "Artsy Partner",
      email_address: "partner@test.com",
      phone_number: "6313667777"
    }
  ]
}

# Build final params hash here!:
params = {
  request: {
    additional_services: [],
    destination: buyer_info,
    objects: [
      physical_artwork_info
    ],
    origin: artwork_origin_location_and_contact_info
  }
}

=end
#########################################
#########################################
