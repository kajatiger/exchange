class Mutations::SubmitOrderWithOffer < Mutations::BaseMutation
  null true

  argument :offer_id, ID, required: true
  argument :confirmed_setup_intent_id, String, required: false

  field :order_or_error,
        Mutations::OrderOrFailureUnionType,
        'A union of success/failure',
        null: false

  def resolve(offer_id:, confirmed_setup_intent_id: nil)
    offer = Offer.find(offer_id)
    authorize_offer_owner_request!(offer)

    OfferService.submit_order_with_offer(
      offer,
      user_id: current_user_id,
      confirmed_setup_intent_id: confirmed_setup_intent_id
    )

    { order_or_error: { order: offer.order } }
  rescue Errors::PaymentRequiresActionError => e
    { order_or_error: { action_data: e.action_data } }
  rescue Errors::ApplicationError => e
    {
      order_or_error: { error: Types::ApplicationErrorType.from_application(e) }
    }
  end
end
