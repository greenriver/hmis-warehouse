###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Hud::DataIntegrity::SoleMemberHohFixer, type: :model do
  let!(:hmis_ds) { create :hmis_data_source }
  let!(:p1) { create :hmis_hud_project, data_source: hmis_ds }

  # Sole hh member with RelationshipToHoH 99 - should be corrected to 1
  let!(:sole_99) { create :hmis_hud_enrollment, data_source: hmis_ds, project: p1, relationship_to_hoh: 99 }
  # Sole hh member with RelationshipToHoH nil - should be corrected to 1
  let!(:sole_nil) { create :hmis_hud_enrollment, data_source: hmis_ds, project: p1, relationship_to_hoh: nil }
  # Already HoH is not touched
  let!(:already_hoh) { create :hmis_hud_enrollment, data_source: hmis_ds, project: p1, relationship_to_hoh: 1 }
  # Multi-member household - RelationshipToHoH is not touched
  let!(:multi_a) { create :hmis_hud_enrollment, data_source: hmis_ds, project: p1, relationship_to_hoh: 99, household_id: 'multi-member-household' }
  let!(:multi_b) { create :hmis_hud_enrollment, data_source: hmis_ds, project: p1, relationship_to_hoh: 99, household_id: 'multi-member-household' }

  describe '.for_data_source!' do
    it 'promotes a sole member with RelationshipToHoH 99 to HoH' do
      expect { described_class.for_data_source!(data_source_id: hmis_ds.id) }.to(
        change { Hmis::Hud::Enrollment.find(sole_99.id).relationship_to_hoh }.from(99).to(1),
      )
    end

    it 'promotes a sole member with RelationshipToHoH nil to HoH' do
      expect { described_class.for_data_source!(data_source_id: hmis_ds.id) }.to(
        change { Hmis::Hud::Enrollment.find(sole_nil.id).relationship_to_hoh }.from(nil).to(1),
      )
    end

    it 'leaves an existing sole-member HoH unchanged' do
      expect { described_class.for_data_source!(data_source_id: hmis_ds.id) }.to(
        not_change { Hmis::Hud::Enrollment.find(already_hoh.id).relationship_to_hoh },
      )
    end

    it 'leaves a two-member household unchanged' do
      expect { described_class.for_data_source!(data_source_id: hmis_ds.id) }.to(
        not_change { Hmis::Hud::Enrollment.find(multi_a.id).relationship_to_hoh }.
        and(not_change { Hmis::Hud::Enrollment.find(multi_b.id).relationship_to_hoh }),
      )
    end

    it 'returns the number of updated records' do
      expect(described_class.for_data_source!(data_source_id: hmis_ds.id)).to eq(2)
    end

    [nil, ''].each do |blank_household_id|
      context "with HouseholdID #{blank_household_id.inspect}" do
        let!(:blank_hh) do
          create(:hmis_hud_enrollment, data_source: hmis_ds, project: p1, relationship_to_hoh: 99).tap do |enrollment|
            enrollment.update_columns(HouseholdID: blank_household_id)
          end
        end

        it 'leaves it unchanged' do
          expect { described_class.for_data_source!(data_source_id: hmis_ds.id) }.to(
            not_change { Hmis::Hud::Enrollment.find(blank_hh.id).relationship_to_hoh },
          )
        end
      end
    end

    context 'with enrollments in a different data source' do
      let!(:other_ds) { create(:hmis_data_source) }
      let!(:other_enrollment) { create :hmis_hud_enrollment, data_source: other_ds, relationship_to_hoh: 99 }

      it 'does not touch them' do
        expect { described_class.for_data_source!(data_source_id: hmis_ds.id) }.to(
          not_change { Hmis::Hud::Enrollment.find(other_enrollment.id).relationship_to_hoh },
        )
      end
    end
  end

  describe '.run! with an explicit scope' do
    let!(:sole_99_out_of_scope) { create :hmis_hud_enrollment, data_source: hmis_ds, project: p1, relationship_to_hoh: 99 }

    it 'only processes records within the provided scope' do
      scope = Hmis::Hud::Enrollment.hmis.where(EnrollmentID: sole_99.enrollment_id)

      expect { described_class.run!(scope: scope) }.to(
        change { Hmis::Hud::Enrollment.find(sole_99.id).relationship_to_hoh }.from(99).to(1).
        and(not_change { Hmis::Hud::Enrollment.find(sole_99_out_of_scope.id).relationship_to_hoh }),
      )
    end
  end

  describe '.run! when the scope includes deleted enrollments' do
    let(:scope) { Hmis::Hud::Enrollment.hmis.with_deleted.where(data_source_id: hmis_ds.id) }

    context 'with a deleted sole member' do
      let!(:deleted_sole) do
        create(:hmis_hud_enrollment, data_source: hmis_ds, project: p1, relationship_to_hoh: 99).tap do |enrollment|
          enrollment.update_columns(DateDeleted: Time.current)
        end
      end

      it 'does not update the deleted enrollment' do
        expect { described_class.run!(scope: scope) }.to(
          not_change { Hmis::Hud::Enrollment.with_deleted.find(deleted_sole.id).relationship_to_hoh },
        )
      end
    end

    context 'with a deleted second household member' do
      let!(:live_member) do
        create :hmis_hud_enrollment, data_source: hmis_ds, project: p1, relationship_to_hoh: 99, household_id: 'hh-with-deleted'
      end
      let!(:deleted_member) do
        create(:hmis_hud_enrollment, data_source: hmis_ds, project: p1, relationship_to_hoh: 1, household_id: 'hh-with-deleted').tap do |enrollment|
          enrollment.update_columns(DateDeleted: Time.current)
        end
      end

      it 'promotes the live member and does not update the deleted member' do
        expect { described_class.run!(scope: scope) }.to(
          change { Hmis::Hud::Enrollment.find(live_member.id).relationship_to_hoh }.from(99).to(1).
          and(not_change { Hmis::Hud::Enrollment.with_deleted.find(deleted_member.id).relationship_to_hoh }),
        )
      end
    end
  end
end
