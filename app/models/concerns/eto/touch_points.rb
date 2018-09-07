module Eto::TouchPoints
  extend ActiveSupport::Concern
  included do

    has_many :client_attributes_defined_text, class_name: GrdaWarehouse::HMIS::ClientAttributeDefinedText.name, inverse_of: :client
    has_many :hmis_forms, class_name: GrdaWarehouse::HmisForm.name
    has_many :non_confidential_hmis_forms, -> do
      joins(:hmis_forms).where(id: GrdaWarehouse::HmisForm.window.non_confidential.select(:id))
    end, class_name: GrdaWarehouse::HmisForm.name

    has_many :coc_assessment_touch_points, -> do
      where(name: 'Boston CoC Coordinated Entry Assessment')
    end, class_name: GrdaWarehouse::HmisForm.name, through: :source_clients, source: :hmis_forms

    # Health Related TouchPoints
    has_many :self_sufficiency_assessments, -> { where(name: 'Self-Sufficiency Matrix')}, class_name: GrdaWarehouse::HmisForm.name, through: :source_clients, source: :hmis_forms
    has_many :case_management_notes, -> { where(name: ['SDH Case Management Note', 'Case Management Daily Note'])}, class_name: GrdaWarehouse::HmisForm.name, through: :source_clients, source: :hmis_forms
    has_many :health_touch_points, -> do
      merge(GrdaWarehouse::HmisForm.health)
    end, class_name: GrdaWarehouse::HmisForm.name, through: :source_clients, source: :hmis_forms

    def most_recent_coc_assessment_score
      assessment = coc_assessment_touch_points.newest_first.limit(1).first

      relevant_section = assessment.answers[:sections].select do |section|
        section[:section_title].downcase.include?('assessment score') && section[:questions].present?
      end&.first
      return nil unless relevant_section.present?

      relevant_question = relevant_section[:questions].select do |question|
        question[:question].downcase == 'boston coordinated entry assessment total score'
      end&.first.try(:[], :answer)
      relevant_question&.to_i
    end
  end
end