module Types::Events::EventInterface
  include Types::BaseInterface
  field :created_at, Types::DateTimeType, null: false
end
