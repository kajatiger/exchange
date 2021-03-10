class Types::Events::OrderStateChangedEvent < Types::BaseObject
  implements Types::Events::EventInterface
  field :state, Types::OrderStateEnum, null: false
  field :state_reason, String, null: true
end
