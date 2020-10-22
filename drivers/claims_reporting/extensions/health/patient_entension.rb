require 'memoist'
raise 'foo'
module ClaimsReporting::Health
  module PatientExtension
    extend ActiveSupport::Concern
    extend Memoist
    has_many :medical_claims, class_name: 'ClaimsReporting::MedicalClaim', foreign_key: :member_id, primary_key: :medicaid_id

    included do
      def medical_claims_for_qualifying_activity(qa)

        activity_date_range = Range.new *qualifying_activities.map(&:date_of_activity).minmax

        matching_claims = (
          medical_claims_by_service_start_date(date_range: activity_date_range)[qa.date_of_activity] || []
        ).select do |c|
          qa.procedure_code == c.procedure_code && qa.modifiers.to_set == c.modifiers.to_set
        end
      end

      def best_medical_claim_for_qualifying_activity(qa)
        matching_claims = medical_claims_for_qualifying_activity(qa)

        matching_claims.first if matching_claims.size <= 1

        # slow path -- more that one matching claim for the same day
        # we can try to assign them in matching order by id
        matching_qa = qualifying_activities.select do |qa2|
          (
            qa2.claim_submitted_on.present? &&
            qa2.date_of_activity == qa.date_of_activity &&
            qa2.procedure_code == qa.procedure_code &&
            qa2.modifiers.to_set == qa.modifiers.to_set
          )
        end

        return nil unless matching_qa.size == matching_claims.size
        matching_claims[matching_qa.index(qa)]
      end

      def medical_claims_by_service_start_date(date_range: )
        medical_claims.where(
          service_start_date: date_range
        ).group_by{|c| c.service_start_date}
      end
      memoize :medical_claims_by_service_start_date
    end
  end
end
