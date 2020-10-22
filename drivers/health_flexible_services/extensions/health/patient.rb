module HealthFlexibleServices::Health
  module PatientExtension
    extend ActiveSupport::Concern
    included do
      has_many :flexible_services # , class_name: 'HealthFlexibleServices::Vpr'
      has_many :flexible_service_follow_ups # , class_name: 'HealthFlexibleServices::VprFollowUp'
    end
  end
end
