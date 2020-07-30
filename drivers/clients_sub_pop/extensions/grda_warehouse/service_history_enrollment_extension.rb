module ClientsSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :clients, -> do
        current_scope
      end

      scope :all_clients, -> do
        current_scope
      end
    end
  end
end
