module OfferQueryHelper
  CREATE_OFFER_ORDER = %(
    mutation($input: CreateOfferOrderWithArtworkInput!) {
      createOfferOrderWithArtwork(input: $input) {
        orderOrError {
          ... on OrderWithMutationSuccess {
            order {
              id
            }
          }
          ... on OrderWithMutationFailure {
            error {
              code
              data
              type
            }
          }
        }
      }
    }
  ).freeze

  CREATE_INQUIRY_OFFER_ORDER = %(
    mutation($input: CreateInquiryOfferOrderWithArtworkInput!) {
      createInquiryOfferOrderWithArtwork(input: $input) {
        orderOrError {
          ... on OrderWithMutationSuccess {
            order {
              id
              ... on OfferOrder {
                impulseConversationId
              }
            }
          }
          ... on OrderWithMutationFailure {
            error {
              code
              data
              type
            }
          }
        }
      }
    }
  ).freeze

  ADD_OFFER_TO_ORDER = %(
    mutation($input: AddInitialOfferToOrderInput!) {
      addInitialOfferToOrder(input: $input) {
        orderOrError {
          ... on OrderWithMutationSuccess {
            order {
              id
            }
          }
          ... on OrderWithMutationFailure {
            error {
              code
              data
              type
            }
          }
        }
      }
    }
  ).freeze

  SUBMIT_PENDING_OFFER = %(
    mutation($input: SubmitPendingOfferInput!) {
      submitPendingOffer(input: $input) {
        orderOrError {
          ... on OrderWithMutationSuccess {
            order {
              id
              state
              ... on OfferOrder {
                lastOffer {
                  id
                  submittedAt
                }
              }
            }
          }
          ... on OrderWithMutationFailure {
            error {
              code
              data
              type
            }
          }
        }
      }
    }
  ).freeze

  SELLER_ACCEPT_OFFER = %(
    mutation($input: SellerAcceptOfferInput!) {
      sellerAcceptOffer(input: $input) {
        orderOrError {
          ... on OrderWithMutationSuccess {
            order {
              id
              state
            }
          }
          ... on OrderWithMutationFailure {
            error {
              code
              data
              type
            }
          }
        }
      }
    }
  ).freeze

  BUYER_ACCEPT_OFFER = %(
    mutation($input: BuyerAcceptOfferInput!) {
      buyerAcceptOffer(input: $input) {
        orderOrError {
          ... on OrderWithMutationSuccess {
            order {
              id
              state
            }
          }
          ... on OrderWithMutationFailure {
            error {
              code
              data
              type
            }
          }
        }
      }
    }
  ).freeze

  SELLER_COUNTER_OFFER = %(
    mutation($input: SellerCounterOfferInput!) {
      sellerCounterOffer(input: $input) {
        orderOrError {
          ... on OrderWithMutationSuccess {
            order {
              id
              state
            }
          }
          ... on OrderWithMutationFailure {
            error {
              code
              data
              type
            }
          }
        }
      }
    }
  ).freeze

  SUBMIT_ORDER_WITH_OFFER = %(
    mutation($input: SubmitOrderWithOfferInput!) {
      submitOrderWithOffer(input: $input) {
        orderOrError {
          ... on OrderWithMutationSuccess {
            order {
              id
              state
              ... on OfferOrder {
                lastOffer {
                  id
                  submittedAt
                  currencyCode
                }
              }
            }
          }
          ... on OrderWithMutationFailure {
            error {
              code
              data
              type
            }
          }
        }
      }
    }
  ).freeze

  FAILED_PAYMENT_QUERY = %(
    mutation($input: FixFailedPaymentInput!) {
      fixFailedPayment(input: $input) {
        orderOrError {
          ... on OrderWithMutationSuccess {
            order {
              id
              state
              creditCardId
              buyer {
                ... on Partner {
                  id
                }
              }
              seller {
                ... on User {
                  id
                }
              }
            }
          }
          ... on OrderWithMutationFailure {
            error {
              code
              data
              type
            }
          }
          ... on OrderRequiresAction {
            actionData {
              clientSecret
            }
          }
        }
      }
    }
  ).freeze
end
