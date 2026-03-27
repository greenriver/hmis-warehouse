###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ProjectCleanup, type: :model do
  let!(:data_source) { create(:source_data_source) }
  let!(:project) { create(:hud_project, data_source: data_source, ProjectType: 1) }

  subject(:cleaner) { described_class.new(project_ids: [project.id]) }

  # Helpers to create records belonging to the project
  def create_project_coc(coc_code)
    create(:hud_project_coc, ProjectID: project.ProjectID, data_source: data_source, CoCCode: coc_code)
  end

  def create_enrollment(coc_code)
    create(:hud_enrollment, ProjectID: project.ProjectID, data_source_id: data_source.id, EnrollmentCoC: coc_code)
  end

  def create_hmis_participation(id)
    create(:hud_hmis_participation, ProjectID: project.ProjectID, data_source: data_source, HMISParticipationID: id)
  end

  def create_she(project_name:, client_id:)
    create(:she_entry, project_id: project.ProjectID, data_source_id: data_source.id,
                       project_name: project_name, client_id: client_id, date: Date.current,
                       first_date_in_program: Date.current)
  end

  describe '#fix_client_locations' do
    context 'when skip_location_cleanup is true' do
      subject(:cleaner) { described_class.new(project_ids: [project.id], skip_location_cleanup: true) }

      before do
        create_project_coc('XX-500')
      end

      let!(:enrollment) { create_enrollment('XX-001') }

      it 'does not modify enrollment CoC codes' do
        expect { cleaner.fix_client_locations(project) }.
          not_to(change { enrollment.reload.EnrollmentCoC })
      end
    end

    context 'when project has no project_cocs' do
      let!(:enrollment) { create_enrollment('XX-001') }

      it 'does not modify enrollment CoC codes' do
        expect { cleaner.fix_client_locations(project) }.
          not_to(change { enrollment.reload.EnrollmentCoC })
      end
    end

    context 'when all project_coc codes are invalid' do
      before { create_project_coc('INVALID-CODE') }

      let!(:enrollment) { create_enrollment('XX-001') }

      it 'does not modify enrollment CoC codes' do
        expect { cleaner.fix_client_locations(project) }.
          not_to(change { enrollment.reload.EnrollmentCoC })
      end
    end

    context 'with a single valid CoC code' do
      before { create_project_coc('XX-500') }

      context 'when an enrollment has a mismatched CoC code' do
        let!(:enrollment) { create_enrollment('XX-001') }

        it 'updates the enrollment CoC to the project CoC' do
          cleaner.fix_client_locations(project)
          expect(enrollment.reload.EnrollmentCoC).to eq('XX-500')
        end

        it 'clears the source_hash on updated enrollments' do
          enrollment.update_column(:source_hash, 'stale_hash')
          cleaner.fix_client_locations(project)
          expect(enrollment.reload.source_hash).to be_nil
        end
      end

      context 'when an enrollment has a NULL CoC code' do
        let!(:enrollment) { create_enrollment(nil) }

        it 'updates the enrollment CoC to the project CoC' do
          cleaner.fix_client_locations(project)
          expect(enrollment.reload.EnrollmentCoC).to eq('XX-500')
        end
      end

      context 'with a mix of matching and mismatched enrollments' do
        let!(:matching_enrollment) { create_enrollment('XX-500') }
        let!(:mismatched_enrollment) { create_enrollment('XX-001') }

        it 'corrects only the mismatched enrollment' do
          cleaner.fix_client_locations(project)
          expect(matching_enrollment.reload.EnrollmentCoC).to eq('XX-500')
          expect(mismatched_enrollment.reload.EnrollmentCoC).to eq('XX-500')
        end
      end
    end

    context 'with multiple valid CoC codes' do
      before do
        create_project_coc('XX-500')
        create_project_coc('XX-501')
      end

      context 'when an enrollment does not match any CoC code' do
        let!(:enrollment) { create_enrollment('XX-001') }

        it 'clears the enrollment CoC' do
          cleaner.fix_client_locations(project)
          expect(enrollment.reload.EnrollmentCoC).to be_nil
        end
      end

      context 'with a mix of matching and non-matching enrollments' do
        let!(:matching_enrollment) { create_enrollment('XX-501') }
        let!(:non_matching_enrollment) { create_enrollment('XX-002') }

        it 'only clears the non-matching enrollment CoC' do
          cleaner.fix_client_locations(project)
          expect(matching_enrollment.reload.EnrollmentCoC).to eq('XX-501')
          expect(non_matching_enrollment.reload.EnrollmentCoC).to be_nil
        end
      end
    end
  end

  describe '#fix_name' do
    let!(:client) { create(:hud_client, data_source: data_source) }

    context 'when SHE records have a stale project name' do
      let!(:she) { create_she(project_name: 'Old Name', client_id: client.id) }

      it 'updates the SHE project name to match the current project' do
        cleaner.fix_name(project)
        expect(she.reload.project_name).to eq(project.ProjectName)
      end
    end
  end

  describe '#remove_unneeded_hmis_participations' do
    context 'when only migration-generated (GR- prefixed) participations exist' do
      let!(:gr_participation) { create_hmis_participation('GR-001') }

      it 'does not remove any participations' do
        expect { cleaner.remove_unneeded_hmis_participations(project) }.
          not_to(change { project.hmis_participations.count })
      end
    end

    context 'when only user-provided (non-GR) participations exist' do
      let!(:user_participation) { create_hmis_participation('USER-001') }

      it 'does not remove any participations' do
        expect { cleaner.remove_unneeded_hmis_participations(project) }.
          not_to(change { project.hmis_participations.count })
      end
    end

    context 'when both GR- prefixed and user-provided participations exist' do
      let!(:gr_participation) { create_hmis_participation('GR-001') }
      let!(:user_participation) { create_hmis_participation('USER-001') }

      it 'removes the GR- prefixed participation' do
        cleaner.remove_unneeded_hmis_participations(project)
        expect(project.hmis_participations.reload).to contain_exactly(user_participation)
      end
    end
  end
end
