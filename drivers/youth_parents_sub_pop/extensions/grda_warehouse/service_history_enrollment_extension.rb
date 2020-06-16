module YouthParentsSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :youth_parents, -> do
        # TODO
        all
      end
    end
  end
end