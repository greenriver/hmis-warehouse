module ClientsSubPop::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :clients, ->  do
        current_scope
      end
    end
  end
end