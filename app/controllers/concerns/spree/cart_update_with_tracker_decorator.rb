module Spree
  module CartUpdateWithTrackerDecorator

    def call(order:, params:)
      return failure(order) unless order.update(filter_order_items(order, params))
      order.line_items.each do |line_item|
        if line_item.previous_changes.keys.include?('quantity')
          Spree::Cart::Event::Tracker.new(
            actor: order, target: line_item, total: order.total, variant_id: line_item.variant_id
          ).track
        end
      end

      order.line_items = order.line_items.select { |li| li.quantity > 0 }
      # Update totals, then check if the order is eligible for any cart promotions.
      # If we do not update first, then the item total will be wrong and ItemTotal
      # promotion rules would not be triggered.
      ActiveRecord::Base.transaction do
        order.update_with_updater!
        ::Spree::PromotionHandler::Cart.new(order).activate
        order.ensure_updated_shipments
        order.payments.store_credits.checkout.destroy_all
        order.update_with_updater!
      end
      success(order)
    end
  end
end

Spree::Cart::Update.send(:prepend, Spree::CartUpdateWithTrackerDecorator)
