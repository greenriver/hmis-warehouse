###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EpicGoal < EpicBase
    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier, 'ID of goal'
    phi_attr :entered_by, Phi::NeedsReview
    phi_attr :id_in_source, Phi::OtherIdentifier
    phi_attr :ordered_date, Phi::Date, 'Ordered date'
    phi_attr :goal_created_at, Phi::Date, "Date of goal's creation"
    phi_attr :title, Phi::FreeText, 'Title of goal'
    phi_attr :contents, Phi::FreeText, 'Content of goal'
    phi_attr :received_valid_complaint, Phi::NeedsReview

    belongs_to :epic_patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_goals, optional: true
    has_many :patient, through: :epic_patient

    scope :visible, -> do
      where(arel_table[:title].matches('SDH%'))
    end

    self.source_key = :GOAL_ID

    def self.csv_map(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        PAT_ID: :patient_id,
        GOAL_ID: :id_in_source,
        goal_created: :goal_created_at,
        entered_by: :entered_by,
        title: :title,
        contents: :contents,
        REC_VAL_COMPLIAN_YN: :received_valid_complaint,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end

    def objective
      part(:objective)
    end

    def steps
      part(:steps)
    end

    def team
      part(:team)
    end

    def part(section)
      objective = 'Objective:'
      steps = 'Steps to reach goal:'
      team = 'Team members contributing to achieve goal:'
      @parts ||= {
        objective: contents.match(/#{objective} +(.+?)  #{steps}/).try(:[], 1),
        steps: contents.match(/#{steps} +(.+?)  #{team}/).try(:[], 1),
        team: contents.match(/#{team} +(.+?)  /).try(:[], 1),
      }
      @parts[section]
    end
  end
end
