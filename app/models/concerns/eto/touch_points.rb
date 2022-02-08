###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Eto
  module TouchPoints
    extend ActiveSupport::Concern
    included do
      has_many :client_attributes_defined_text, class_name: 'GrdaWarehouse::HMIS::ClientAttributeDefinedText', inverse_of: :client
      has_many :hmis_forms, class_name: 'GrdaWarehouse::HmisForm'
      has_many :non_confidential_hmis_forms, -> do
        joins(:hmis_forms).where(id: GrdaWarehouse::HmisForm.window.non_confidential.select(:id))
      end, class_name: 'GrdaWarehouse::HmisForm'

      has_many :coc_assessment_touch_points, -> do
        where(name: 'Boston CoC Coordinated Entry Assessment')
      end, class_name: 'GrdaWarehouse::HmisForm', through: :source_clients, source: :hmis_forms

      # Health Related TouchPoints
      has_many :self_sufficiency_assessments, -> { where(name: 'Self-Sufficiency Matrix') }, class_name: 'GrdaWarehouse::HmisForm', through: :source_clients, source: :hmis_forms
      has_many :case_management_notes, -> { where(name: ['SDH Case Management Note', 'Case Management Daily Note']) }, class_name: 'GrdaWarehouse::HmisForm', through: :source_clients, source: :hmis_forms
      has_many :health_touch_points, -> do
        merge(GrdaWarehouse::HmisForm.health)
      end, class_name: 'GrdaWarehouse::HmisForm', through: :source_clients, source: :hmis_forms
      has_one :most_recent_tc_hat, -> do
        one_for_column(
          :collected_at,
          source_arel_table: hmis_form_t,
          group_on: [:client_id],
          scope: where(name: 'HAT (TX-601 Housing Assessment Tool )'),
        )
      end, class_name: 'GrdaWarehouse::HmisForm'

      def most_recent_coc_assessment_score
        assessment = coc_assessment_touch_points.newest_first.limit(1).first
        return nil unless assessment.present?

        relevant_section = assessment.answers[:sections].select do |section|
          section[:section_title].downcase.include?('assessment score') && section[:questions].present?
        end&.first
        return nil unless relevant_section.present?

        relevant_question = relevant_section[:questions].select do |question|
          question[:question].casecmp('boston coordinated entry assessment total score').zero?
        end&.first.try(:[], :answer)
        relevant_question&.to_i
      end
    end
  end
end
