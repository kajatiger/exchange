class InventoryService
  def initialize(order)
    @order = order
    @deducted_items = []
  end

  def check_inventory!
    raise Errors::InsufficientInventoryError unless @order.inventory?
  end

  def deduct_inventory!
    @order.line_items.each do |item|
      Gravity.deduct_inventory(item)
      @deducted_items << item
    end
  end

  def undeduct_inventory!
    until @deducted_items.empty?
      Gravity.undeduct_inventory(@deducted_items.first)
      @deducted_items.shift
    end
  end
end
