# This is an autogenerated file for routes helper methods

# typed: strong
class ActionController::Base
  extend T::Sig

  # Sigs for route /admin(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_root_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_root_url(*args, **kwargs); end

  # Sigs for route /admin/orders/:id/refund(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def refund_admin_order_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def refund_admin_order_url(*args, **kwargs); end

  # Sigs for route /admin/orders/:id/buyer_reject(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def buyer_reject_admin_order_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def buyer_reject_admin_order_url(*args, **kwargs); end

  # Sigs for route /admin/orders/:id/approve_order(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def approve_order_admin_order_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def approve_order_admin_order_url(*args, **kwargs); end

  # Sigs for route /admin/orders/:id/accept_offer(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def accept_offer_admin_order_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def accept_offer_admin_order_url(*args, **kwargs); end

  # Sigs for route /admin/orders/:id/confirm_pickup(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def confirm_pickup_admin_order_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def confirm_pickup_admin_order_url(*args, **kwargs); end

  # Sigs for route /admin/orders/:id/confirm_fulfillment(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def confirm_fulfillment_admin_order_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def confirm_fulfillment_admin_order_url(*args, **kwargs); end

  # Sigs for route /admin/orders/:id/toggle_assisted(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def toggle_assisted_admin_order_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def toggle_assisted_admin_order_url(*args, **kwargs); end

  # Sigs for route /admin/orders/batch_action(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def batch_action_admin_orders_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def batch_action_admin_orders_url(*args, **kwargs); end

  # Sigs for route /admin/orders(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_orders_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_orders_url(*args, **kwargs); end

  # Sigs for route /admin/orders/:id(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_order_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_order_url(*args, **kwargs); end

  # Sigs for route /admin/orders/:order_id/admin_notes/batch_action(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def batch_action_admin_order_admin_notes_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def batch_action_admin_order_admin_notes_url(*args, **kwargs); end

  # Sigs for route /admin/orders/:order_id/admin_notes(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_order_admin_notes_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_order_admin_notes_url(*args, **kwargs); end

  # Sigs for route /admin/orders/:order_id/admin_notes/new(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def new_admin_order_admin_note_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def new_admin_order_admin_note_url(*args, **kwargs); end

  # Sigs for route /admin/orders/:order_id/admin_notes/:id/edit(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def edit_admin_order_admin_note_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def edit_admin_order_admin_note_url(*args, **kwargs); end

  # Sigs for route /admin/orders/:order_id/admin_notes/:id(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_order_admin_note_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_order_admin_note_url(*args, **kwargs); end

  # Sigs for route /admin/comments(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_comments_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_comments_url(*args, **kwargs); end

  # Sigs for route /admin/comments/:id(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_comment_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_comment_url(*args, **kwargs); end

  # Sigs for route /
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def artsy_auth_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def artsy_auth_url(*args, **kwargs); end

  # Sigs for route /admin/sidekiq
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def sidekiq_web_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def sidekiq_web_url(*args, **kwargs); end

  # Sigs for route /api/graphql(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def api_graphql_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def api_graphql_url(*args, **kwargs); end

  # Sigs for route /api/health(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def api_health_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def api_health_url(*args, **kwargs); end

  # Sigs for route /api/webhooks/stripe(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def api_webhooks_stripe_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def api_webhooks_stripe_url(*args, **kwargs); end

  # Sigs for route /admin_notes(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_notes_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_notes_url(*args, **kwargs); end

  # Sigs for route /admin_notes/new(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def new_admin_note_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def new_admin_note_url(*args, **kwargs); end

  # Sigs for route /admin_notes/:id/edit(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def edit_admin_note_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def edit_admin_note_url(*args, **kwargs); end

  # Sigs for route /admin_notes/:id(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_note_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def admin_note_url(*args, **kwargs); end

  # Sigs for route /
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def root_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def root_url(*args, **kwargs); end

  # Sigs for route /rails/active_storage/blobs/:signed_id/*filename(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def rails_service_blob_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def rails_service_blob_url(*args, **kwargs); end

  # Sigs for route /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def rails_blob_representation_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def rails_blob_representation_url(*args, **kwargs); end

  # Sigs for route /rails/active_storage/disk/:encoded_key/*filename(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def rails_disk_service_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def rails_disk_service_url(*args, **kwargs); end

  # Sigs for route /rails/active_storage/disk/:encoded_token(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def update_rails_disk_service_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def update_rails_disk_service_url(*args, **kwargs); end

  # Sigs for route /rails/active_storage/direct_uploads(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def rails_direct_uploads_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def rails_direct_uploads_url(*args, **kwargs); end


  # Section Routes for ArtsyAuth::Engine
  # Sigs for route /sign_out(.:format)
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def sign_out_path(*args, **kwargs); end
  sig { params(args: T.untyped, kwargs: T.untyped).returns(String) }
  def sign_out_url(*args, **kwargs); end

end
