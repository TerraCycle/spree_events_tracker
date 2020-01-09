module Spree
  module CartRemoveItemWithTrackerDecorator
    def remove_from_line_item(order:, variant:, quantity:, options:)
      line_item = Spree::Dependencies.line_item_by_variant_finder.constantize.new.execute(order: order, variant: variant, options: options)

      raise ActiveRecord::RecordNotFound if line_item.nil?

      line_item.quantity -= quantity
      line_item.target_shipment = options[:shipment]

      if line_item.quantity.zero?
        # In Cart Event Tracker, we use DirtyObject's previous_changes method.
        # Following statement handles the case, when we delete a line_item from order's shipments page (from back_end)
        line_item.update(quantity: 0)
        order.line_items.destroy(line_item)
      else
        line_item.save!
      end

      Spree::Cart::Event::Tracker.new(
        actor: order, target: line_item, total: order.total, variant_id: line_item.variant_id
      ).track

      line_item
    end
  end
end

Spree::Cart::RemoveItem.send(:prepend, Spree::CartRemoveItemWithTrackerDecorator)
