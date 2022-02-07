###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'
module ClaimsReporting::Health
  module PatientExtension
    extend ActiveSupport::Concern

    included do
      extend Memoist

      has_many :medical_claims, class_name: 'ClaimsReporting::MedicalClaim', foreign_key: :member_id, primary_key: :medicaid_id

      def medical_claims_for_qualifying_activity(qa, denied: false) # rubocop:disable Naming/MethodParameterName
        activity_date_range = Range.new(*qualifying_activities.map(&:date_of_activity).minmax)

        (
          medical_claims_by_service_start_date(date_range: activity_date_range)[qa.date_of_activity] || []
        ).select do |c|
          procedure_matches = qa.procedure_with_modifiers == c.procedure_with_modifiers
          procedure_matches &&= c.claim_status == 'D' if denied

          procedure_matches
        end
      end

      def best_medical_claim_for_qualifying_activity(qa, denied: false) # rubocop:disable Naming/MethodParameterName
        matching_claims = medical_claims_for_qualifying_activity(qa, denied: denied)

        return matching_claims.first if matching_claims.size <= 1

        # slow path -- more that one matching claim for the same day
        # we can try to assign them in matching order by id
        matching_qa = qualifying_activities.select do |qa2|
          (
            qa2.claim_submitted_on.present? &&
            qa2.date_of_activity == qa.date_of_activity &&
            qa2.procedure_with_modifiers == qa.procedure_with_modifiers
          )
        end

        return nil unless matching_qa.size == matching_claims.size
        return nil if matching_qa.index(qa).nil?

        matching_claims[matching_qa.index(qa)]
      end

      def medical_claims_by_service_start_date(date_range:)
        medical_claims.where(
          service_start_date: date_range,
        ).group_by(&:service_start_date)
      end
      memoize :medical_claims_by_service_start_date
    end
  end
end
