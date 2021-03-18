class Types::Events::OfferSubmittedEvent < Types::BaseObject
  implements Types::Events::EventInterface
  field :offer, Types::OfferType, null: false
end
