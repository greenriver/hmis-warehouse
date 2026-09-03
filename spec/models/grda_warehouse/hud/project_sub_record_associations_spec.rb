###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Project, type: :model do
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:project) do
    create(:hud_project, data_source_id: data_source.id, ProjectType: 1)
  end
  let(:other_project) do
    create(:hud_project, data_source_id: data_source.id, ProjectType: 1)
  end
  let(:enrollment) do
    create(
      :hud_enrollment,
      data_source_id: data_source.id,
      ProjectID: project.ProjectID,
    )
  end
  let(:other_enrollment) do
    create(
      :hud_enrollment,
      data_source_id: data_source.id,
      ProjectID: other_project.ProjectID,
    )
  end

  describe '#current_living_situations' do
    it 'returns only situations reached through this project\'s enrollments' do
      mine = create(
        :hud_current_living_situation,
        data_source_id: data_source.id,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
      )
      create(
        :hud_current_living_situation,
        data_source_id: data_source.id,
        EnrollmentID: other_enrollment.EnrollmentID,
        PersonalID: other_enrollment.PersonalID,
      )

      expect(project.current_living_situations).to contain_exactly(mine)
    end
  end

  describe '#youth_education_statuses' do
    it 'returns only statuses reached through this project\'s enrollments' do
      mine = create(
        :hud_youth_education_status,
        data_source_id: data_source.id,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
      )
      create(
        :hud_youth_education_status,
        data_source_id: data_source.id,
        EnrollmentID: other_enrollment.EnrollmentID,
        PersonalID: other_enrollment.PersonalID,
      )

      expect(project.youth_education_statuses).to contain_exactly(mine)
    end
  end
end
