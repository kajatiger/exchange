def gravity_v1_artwork(options = {})
  {
    artist: {
      _id: 'artist-id',
      id: 'artist-slug',
      name: 'BNMOsy',
      years: 'born 1953',
      public: true,
      birthday: '1953',
      consignable: true,
      deathday: '',
      nationality: 'American',
      published_artworks_count: 382,
      forsale_artworks_count: 221,
      artworks_count: 502,
      original_width: nil,
      original_height: nil,
      image_url: 'http:///:version.jpg',
      image_versions: %w[large square],
      image_urls:
          {
            large: 'http://large.jpg',
            square: 'http://square.jpg'
          }
    },
    partner: {
      partner_categories: [],
      _id: 'gravity-partner-id',
      id: 'gravity-partner-slug',
      default_profile_id: 'defualt-profile-id',
      default_profile_public: true,
      sortable_id: 'sortable-id',
      type: 'Gallery',
      name: 'BNMO',
      short_name: '',
      website: 'http://www.BNMO.com'
    },
    images: [{
      id: '54a08d8d7261692ce5c50300',
      position: 1,
      aspect_ratio: 0.69,
      downloadable: false,
      original_width: 412,
      original_height: 598,
      is_default: true,
      image_url:
        'https://d32dm0rphc51dk.cloudfront.net/EdrogYFIC2iS0H4myfs1Kw/:version.jpg',
      image_versions:
        %w[small
           square
           tall],
      image_urls:
        {
          small:
          'https:///small.jpg',
          square:
          'https:///square.jpg',
          tall:
          'https:///tall.jpg'
        },
      tile_size: 512,
      tile_overlap: 0,
      tile_format: 'jpg',
      tile_base_url:
        'https:///dztiles',
      max_tiled_height: 598,
      max_tiled_width: 412
    }],
    edition_sets: [{
      id: 'edition-set-id',
      forsale: true,
      sold: false,
      price: '$4200',
      price_listed: 4200.42,
      price_currency: 'USD',
      acquireable: false,
      dimensions: { in: '44 × 30 1/2 in', cm: '111.8 × 77.5 cm' },
      editions: 'Edition of 15',
      display_price_currency: 'USD (United States Dollar)',
      availability: 'for sale',
      inventory: {
        count: 1,
        unlimited: false
      }
    }],
    artists: [{
      _id: 'artist-id',
      id: 'artist-slug',
      sortable_id: 'longo-robert',
      name: 'BNMOsy',
      years: 'born 1953',
      public: true,
      birthday: '1953',
      consignable: true,
      deathday: '',
      nationality: 'American',
      published_artworks_count: 382,
      forsale_artworks_count: 221,
      artworks_count: 502,
      original_width: nil,
      original_height: nil,
      image_url:
        'https://.../:version.jpg',
      image_versions: %w[four_thirds large square tall],
      image_urls:
        { four_thirds:
          'https://.../four_thirds.jpg',
          large:
          'https://.../large.jpg',
          square:
          'https://.../square.jpg',
          tall:
          'https://.../tall.jpg' }
    }],
    location: {
      country: 'US',
      city: 'Brooklyn',
      state: 'NY',
      address: '22 Fake St',
      postal_code: 10013
    },
    _id: 'artwork-id',
    id: 'artwork-slug',
    inventory: {
      count: 1,
      unlimited: false
    },
    current_version_id: 'current-version-id',
    title: 'Untitled Pl. 13 (from Men in the Cities)',
    display: 'BNMOsy, Untitled Pl. 13 (from Men in the Cities) (2005)',
    manufacturer: nil,
    category: 'Photography',
    medium: 'Rag paper',
    unique: nil,
    forsale: true,
    sold: false,
    date: '2005',
    dimensions: { in: '44 × 30 1/2 in', cm: '111.8 × 77.5 cm' },
    price: '$5400',
    price_listed: 5400.12,
    series: '',
    availability: 'for sale',
    availability_hidden: false,
    ecommerce: true,
    tags: [],
    width: '30 1/2',
    height: '44',
    depth: '',
    diameter: nil,
    width_cm: 77.5,
    height_cm: 111.8,
    depth_cm: nil,
    diameter_cm: nil,
    metric: 'in',
    duration: nil,
    website: '',
    signature: '',
    default_image_id: 'default-image',
    edition_sets_count: 1,
    published: true,
    private: false,
    feature_eligible: false,
    price_currency: 'USD',
    inquireable: true,
    acquireable: true,
    offerable: true,
    published_at: '2015-01-08T19:29:54+00:00',
    deleted_at: nil,
    publisher: nil,
    comparables_count: 12,
    cultural_maker: nil,
    sale_ids: [],
    attribution_class: 'limited edition',
    domestic_shipping_fee_cents: 100_00,
    international_shipping_fee_cents: 500_00,
    offerable_from_inquiry: nil
  }.merge(options)
end

def gravity_v1_partner(options = {})
  {
    admin: nil,
    outreach_admin: nil,
    referral_contact: nil,
    partner_categories: [],
    _id: '581b45e4cd530e658b000124',
    id: 'invoicing-demo-partner',
    default_profile_id: 'invoicing-demo-partner',
    default_profile_public: false,
    sortable_id: 'invoicing-demo-partner',
    type: 'Gallery',
    name: 'Invoicing Demo Partner',
    short_name: '',
    pre_qualify: false,
    sortable_name: '',
    given_name: 'Invoicing Demo Partner',
    display_name: '',
    website: 'http://gallery.com',
    email: 'info@gallery.com',
    artists_count: 10,
    partner_artists_count: 10,
    artworks_count: 27,
    artsy_collects_sales_tax: true,
    region: '',
    subscription_state: 'active',
    alternate_names: ['Partner Success Invoicing Demo Partner'],
    contract_type: 'Subscription',
    billing_location_id: '581b46959c18db1dee001f50',
    commission_rate: 0.7,
    effective_commission_rate: 0.8
  }.merge(options)
end
