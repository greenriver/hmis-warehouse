###
# Copyright Green River Data Group, Inc.
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

  def create_enrollment(coc_code, **attrs)
    create(:hud_enrollment, ProjectID: project.ProjectID, data_source_id: data_source.id, EnrollmentCoC: coc_code, **attrs)
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

        it 'preserves the source_hash on updated enrollments' do
          enrollment.update_column(:source_hash, 'current_hash')
          cleaner.fix_client_locations(project)
          expect(enrollment.reload.source_hash).to eq('current_hash')
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

      context 'household CoC propagation' do
        let(:household_id) { 'test-household-1' }

        context 'when HoH has a valid CoC and members have NULL CoC' do
          let!(:hoh) { create_enrollment('XX-500', HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:member) { create_enrollment(nil, HouseholdID: household_id, RelationshipToHoH: 2) }

          it 'propagates HoH CoC to member without modifying the HoH' do
            cleaner.fix_client_locations(project)
            expect(member.reload.EnrollmentCoC).to eq('XX-500')
            expect(hoh.reload.EnrollmentCoC).to eq('XX-500')
          end
        end

        context 'when HoH has a valid CoC and members have a stale valid CoC' do
          let!(:hoh) { create_enrollment('XX-500', HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:member) { create_enrollment('XX-501', HouseholdID: household_id, RelationshipToHoH: 2) }

          it 'overwrites the member CoC with the HoH CoC' do
            cleaner.fix_client_locations(project)
            expect(member.reload.EnrollmentCoC).to eq('XX-500')
          end
        end

        context 'when member already has the same CoC as the HoH' do
          let!(:hoh) { create_enrollment('XX-500', HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:member) { create_enrollment('XX-500', HouseholdID: household_id, RelationshipToHoH: 2) }

          it 'leaves the member CoC unchanged' do
            expect { cleaner.fix_client_locations(project) }.
              not_to(change { member.reload.EnrollmentCoC }.from('XX-500'))
          end
        end

        context 'when HoH has a NULL CoC' do
          let!(:hoh) { create_enrollment(nil, HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:member) { create_enrollment('XX-501', HouseholdID: household_id, RelationshipToHoH: 2) }

          it 'leaves member CoC unchanged' do
            cleaner.fix_client_locations(project)
            expect(member.reload.EnrollmentCoC).to eq('XX-501')
          end
        end

        context 'when the household has no HoH (bad data)' do
          let!(:member1) { create_enrollment('XX-500', HouseholdID: household_id, RelationshipToHoH: 2) }
          let!(:member2) { create_enrollment('XX-501', HouseholdID: household_id, RelationshipToHoH: 3) }

          it 'leaves member CoCs unchanged' do
            cleaner.fix_client_locations(project)
            expect(member1.reload.EnrollmentCoC).to eq('XX-500')
            expect(member2.reload.EnrollmentCoC).to eq('XX-501')
          end
        end

        context 'when the household has multiple HoHs with conflicting CoCs (bad data)' do
          let!(:hoh1) { create_enrollment('XX-500', HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:hoh2) { create_enrollment('XX-501', HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:member) { create_enrollment(nil, HouseholdID: household_id, RelationshipToHoH: 2) }

          it 'skips propagation for the household' do
            cleaner.fix_client_locations(project)
            expect(member.reload.EnrollmentCoC).to be_nil
          end
        end

        context 'when the household has multiple HoHs but only one distinct CoC' do
          let!(:hoh1) { create_enrollment('XX-500', HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:hoh2) { create_enrollment('XX-500', HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:member) { create_enrollment(nil, HouseholdID: household_id, RelationshipToHoH: 2) }

          it 'propagates the unambiguous CoC to the member' do
            cleaner.fix_client_locations(project)
            expect(member.reload.EnrollmentCoC).to eq('XX-500')
          end
        end

        context 'when some HoHs have a NULL CoC but one has a valid CoC' do
          let!(:hoh_with_coc) { create_enrollment('XX-500', HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:hoh_without_coc) { create_enrollment(nil, HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:member) { create_enrollment(nil, HouseholdID: household_id, RelationshipToHoH: 2) }

          it 'propagates the non-NULL CoC to the member' do
            cleaner.fix_client_locations(project)
            expect(member.reload.EnrollmentCoC).to eq('XX-500')
          end
        end

        context 'when a conflicting HoH is soft-deleted' do
          let!(:hoh) { create_enrollment('XX-500', HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:deleted_hoh) { create_enrollment('XX-501', HouseholdID: household_id, RelationshipToHoH: 1, DateDeleted: Time.current) }
          let!(:member) { create_enrollment(nil, HouseholdID: household_id, RelationshipToHoH: 2) }

          it 'ignores the deleted HoH and propagates the active CoC' do
            cleaner.fix_client_locations(project)
            expect(member.reload.EnrollmentCoC).to eq('XX-500')
          end
        end

        context 'when a member is soft-deleted' do
          let!(:hoh) { create_enrollment('XX-500', HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:deleted_member) { create_enrollment(nil, HouseholdID: household_id, RelationshipToHoH: 2, DateDeleted: Time.current) }

          it 'does not update the soft-deleted member' do
            cleaner.fix_client_locations(project)
            expect(deleted_member.reload.EnrollmentCoC).to be_nil
          end
        end

        context 'when a member has a NULL RelationshipToHoH' do
          let!(:hoh) { create_enrollment('XX-500', HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:null_rel_member) { create_enrollment(nil, HouseholdID: household_id, RelationshipToHoH: nil) }

          it 'propagates the HoH CoC to the member' do
            cleaner.fix_client_locations(project)
            expect(null_rel_member.reload.EnrollmentCoC).to eq('XX-500')
          end
        end

        context 'when enrollment has NULL HouseholdID' do
          let!(:hoh) { create_enrollment('XX-500', HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:solo) { create_enrollment('XX-501', HouseholdID: nil, RelationshipToHoH: 1) }

          it 'does not propagate to enrollments without a HouseholdID' do
            cleaner.fix_client_locations(project)
            expect(solo.reload.EnrollmentCoC).to eq('XX-501')
          end
        end

        context 'when another project has a HoH for the same HouseholdID' do
          let!(:other_project) { create(:hud_project, data_source: data_source, ProjectType: 1) }
          # Target project: HoH with NULL CoC, so no propagation should occur
          let!(:hoh) { create_enrollment(nil, HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:member) { create_enrollment(nil, HouseholdID: household_id, RelationshipToHoH: 2) }
          # Other project: HoH with a real CoC that must not leak into the target project
          let!(:cross_project_hoh) do
            create(:hud_enrollment,
                   ProjectID: other_project.ProjectID,
                   data_source_id: data_source.id,
                   EnrollmentCoC: 'XX-500',
                   HouseholdID: household_id,
                   RelationshipToHoH: 1)
          end

          it 'does not use the foreign HoH CoC for propagation' do
            cleaner.fix_client_locations(project)
            expect(member.reload.EnrollmentCoC).to be_nil
          end
        end

        context 'when another data source has a HoH for the same ProjectID and HouseholdID' do
          let!(:other_ds) { create(:source_data_source) }
          # Target DS: HoH with NULL CoC, so no propagation should occur
          let!(:hoh) { create_enrollment(nil, HouseholdID: household_id, RelationshipToHoH: 1) }
          let!(:member) { create_enrollment(nil, HouseholdID: household_id, RelationshipToHoH: 2) }
          # Other DS: HoH with a real CoC that must not leak into the target DS
          let!(:cross_ds_hoh) do
            create(:hud_enrollment,
                   ProjectID: project.ProjectID,
                   data_source_id: other_ds.id,
                   EnrollmentCoC: 'XX-500',
                   HouseholdID: household_id,
                   RelationshipToHoH: 1)
          end

          it 'does not use the foreign HoH CoC for propagation' do
            cleaner.fix_client_locations(project)
            expect(member.reload.EnrollmentCoC).to be_nil
          end
        end

        context 'with two households each having different HoH CoCs' do
          let!(:hoh_a) { create_enrollment('XX-500', HouseholdID: 'household-a', RelationshipToHoH: 1) }
          let!(:member_a) { create_enrollment(nil, HouseholdID: 'household-a', RelationshipToHoH: 2) }
          let!(:hoh_b) { create_enrollment('XX-501', HouseholdID: 'household-b', RelationshipToHoH: 1) }
          let!(:member_b) { create_enrollment(nil, HouseholdID: 'household-b', RelationshipToHoH: 2) }

          it 'propagates each HoH CoC only to its own household' do
            cleaner.fix_client_locations(project)
            expect(member_a.reload.EnrollmentCoC).to eq('XX-500')
            expect(member_b.reload.EnrollmentCoC).to eq('XX-501')
          end
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
