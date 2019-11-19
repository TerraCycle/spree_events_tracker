module Spree::CheckoutControllerDecorator

  include Spree::CheckoutEventTracker

  def self.prepended(base)
    base.after_action :track_order_state_change, only: :edit
    base.after_action :track_order_completion, only: :update, if: :confirm?
  end

  private

  def confirm?
    previous_state == 'confirm'
  end

  def track_order_completion
    track_activity(activity: :complete_order, previous_state: previous_state, next_state: 'complete')
  end

  def track_order_state_change
    unless previous_state == next_state
      track_activity(activity: :change_order_state, previous_state: previous_state, next_state: next_state)
    end
  end
end

::Spree::CheckoutController.prepend(Spree::CheckoutControllerDecorator)
