module ClientsSubPop::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      scope :clients, -> do
        current_scope
      end
    end
  end
end
