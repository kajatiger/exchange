class Types::QueryType < Types::BaseObject
  # Add root-level fields here.
  # They will be entry points for queries on your schema.

  field :order, Types::OrderInterface, null: true do
    description 'Find an order by ID'
    argument :id, ID, required: false
    argument :code, String, required: false
  end

  field :orders, Types::OrderConnectionWithTotalCountType, null: true, connection: true do
    description 'Find list of orders'
    argument :seller_id, String, required: false
    argument :impulse_conversation_id, String, required: false
    argument :seller_type, String, required: false
    argument :buyer_id, String, required: false
    argument :buyer_type, String, required: false
    argument :state, Types::OrderStateEnum, required: false
    argument :sort, Types::OrderConnectionSortEnum, required: false
    argument :mode, Types::OrderModeEnum, required: false
  end

  field :my_orders, Types::OrderConnectionWithTotalCountType, null: true, connection: true do
    description 'Return my orders'
    argument :seller_id, String, required: false
    argument :states, [Types::OrderStateEnum], required: false
    argument :sort, Types::OrderConnectionSortEnum, required: false
    argument :mode, Types::OrderModeEnum, required: false
  end

  field :line_items, Types::LineItemType.connection_type, null: true, connection: true do
    argument :artwork_id, String, required: false
    argument :edition_set_id, String, required: false
    argument :order_states, [Types::OrderStateEnum], required: false
  end

  field :competing_orders, Types::OrderConnectionWithTotalCountType, null: true, connection: true do
    description 'Find list of competing orders'
    argument :order_id, ID, required: true
  end

  def order(args)
    raise Error::ValidationError.new(:missing_required_param, message: 'id or code is required') unless args[:id].present? || args[:code].present?

    order = Order.find_by!(args)
    validate_order_request!(order)
    order
  end

  def orders(params = {})
    validate_orders_request!(params)
    sort = params.delete(:sort)
    order_clause = sort_to_order[sort] || { state_updated_at: :desc }
    Order.where(params).order(order_clause)
  end

  def my_orders(params = {})
    raise ActiveRecord::RecordNotFound unless context[:current_user][:id]

    states = params.delete(:states)
    params = params.merge(state: states) unless states.nil?
    sort = params.delete(:sort)
    order_clause = sort_to_order[sort] || { state_updated_at: :desc }
    Order.where(params.merge(buyer_id: context[:current_user][:id])).order(order_clause)
  end

  def line_items(args = {})
    validate_line_items_request!(args)
    query = LineItem.where(args.slice(:artwork_id, :edition_set_id))
    query = query.joins(:order).where(orders: { state: args[:order_states] }) if args[:order_states].present?
    query
  end

  def competing_orders(params)
    order = Order.find(params[:order_id])
    validate_order_request!(order)
    validate_competing_orders_request!(order)
    order.competing_orders
  end

  private

  def sort_to_order
    {
      'UPDATED_AT_ASC' => { updated_at: :asc },
      'UPDATED_AT_DESC' => { updated_at: :desc },
      'STATE_UPDATED_AT_ASC' => { state_updated_at: :asc },
      'STATE_UPDATED_AT_DESC' => { state_updated_at: :desc },
      'STATE_EXPIRES_AT_ASC' => { state_expires_at: :asc },
      'STATE_EXPIRES_AT_DESC' => { state_expires_at: :desc }
    }
  end

  def trusted?
    context[:current_user][:roles].include?('trusted')
  end

  def trusted_admin?
    user_roles = context[:current_user][:roles].split(',')
    ArtsyAuthToken.trusted_admin?(user_roles)
  end

  def validate_order_request!(order)
    return if trusted? || trusted_admin? ||
              (order.buyer_type == Order::USER && order.buyer_id == context[:current_user][:id]) ||
              (order.seller_type != Order::USER && context[:current_user][:partner_ids].include?(order.seller_id))

    raise ActiveRecord::RecordNotFound
  end

  def validate_line_items_request!(params)
    raise Errors::ValidationError, :not_found unless trusted?
    raise Errors::ValidationError, :missing_params unless params[:artwork_id] || params[:edition_set_id]
  end

  def validate_orders_request!(params)
    return if trusted? || trusted_admin?

    if params[:buyer_id].present?
      raise ActiveRecord::RecordNotFound unless params[:buyer_id] == context[:current_user][:id]
    elsif params[:seller_id].present?
      raise ActiveRecord::RecordNotFound unless context[:current_user][:partner_ids].include?(params[:seller_id])
    else
      raise Errors::ValidationError, :missing_params
    end
  end

  def validate_competing_orders_request!(order)
    not_submitted_error = Errors::ValidationError.new(:order_not_submitted, message: 'order id belongs to order not submitted')
    raise not_submitted_error unless order.state == Order::SUBMITTED
  end
end
