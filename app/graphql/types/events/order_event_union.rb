class Types::Events::OrderEventUnion < Types::BaseUnion
  description 'Represents either a state change or new offer'
  possible_types Types::Events::OfferSubmittedEvent, Types::Events::OrderStateChangedEvent
  def self.resolve_type(object, _context)
    case object
    when OrderHistoryService::OfferSubmitted
      Types::Events::OfferSubmittedEvent
    else
      Types::Events::OrderStateChangedEvent
    end
  end
end
