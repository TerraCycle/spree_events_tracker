module Spree::HomeControllerDecorator
  def self.prepended(base)
    base.include Spree::PageTracker
    base.track_actions [:index]
  end
end

::Spree::HomeController.prepend(Spree::HomeControllerDecorator)
