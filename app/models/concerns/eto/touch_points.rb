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
    has_many :case_management_notes, -> { where(name: 'SDH Case Management Note')}, class_name: GrdaWarehouse::HmisForm.name, through: :source_clients, source: :hmis_forms
    has_many :health_touch_points, -> do
      hmisf_t = GrdaWarehouse::HmisForm.arel_table
      where(hmisf_t[:collection_location].matches('Social Determinants of Health%'))
    end, class_name: GrdaWarehouse::HmisForm.name, through: :source_clients, source: :hmis_forms

    

    def most_recent_coc_assessment_score
      assessment = coc_assessment_touch_points.newest_first.limit(1).first
      return nil unless assessment.present?
      score_section = coc_assessment_touch_points.first.answers[:sections].select do |m| 
        m[:section_title] == "Assessment Score"
      end&.first
      return nil unless score_section.present?
      total_score_question = score_section[:questions].select do |m|
        m[:question] == "Boston Coordinated Entry Assessment Total Score"
      end&.first
      return nil unless total_score_question.present?
      total_score_question.try(:[], :answer).to_i
    end
  end
end