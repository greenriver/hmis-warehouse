# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::HouseholdContextBuilder, type: :model do
  let(:report) { create(:hud_reports_report_instance, start_date: '2020-01-01', end_date: '2020-12-31') }
  let(:generator) do
    instance_double(
      HudReports::GeneratorBase,
      client_scope: GrdaWarehouse::Hud::Client.where(id: [client_hoh.destination_client.id, client_child.destination_client.id]),
      report_scope_source: GrdaWarehouse::ServiceHistoryEnrollment.entry
    )
  end

  let!(:data_source) { create(:data_source_fixed_id) }
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:project) { create(:hud_project, data_source: data_source, organization: organization, ProjectType: 1) } # ES-NBN

  # Clients: HoH (Adult) + Child
  let(:client_hoh) { create_client_with_warehouse_link(dob: 40.years.ago) }
  let(:client_child) { create_client_with_warehouse_link(dob: 10.years.ago) }

  def create_client_with_warehouse_link(dob:)
    source_client = create(:hud_client, data_source: data_source, DOB: dob)
    dest_client = create(:hud_client, data_source: data_source, DOB: dob)
    create(:warehouse_client, source: source_client, destination: dest_client)
    create(:grda_warehouse_warehouse_clients_processed, client_id: dest_client.id, warehouse_client: GrdaWarehouse::WarehouseClient.last)
    source_client
  end

  # HUD Enrollments
  let!(:hud_enrollment_hoh) do
    create(:hud_enrollment,
           PersonalID: client_hoh.PersonalID,
           ProjectID: project.ProjectID,
           HouseholdID: 'HH123',
           RelationshipToHoH: 1, # Self (HoH)
           EntryDate: '2020-01-01',
           data_source_id: data_source.id)
  end

  let!(:hud_enrollment_child) do
    create(:hud_enrollment,
           PersonalID: client_child.PersonalID,
           ProjectID: project.ProjectID,
           HouseholdID: 'HH123',
           RelationshipToHoH: 2, # Child
           EntryDate: '2020-01-01',
           data_source_id: data_source.id)
  end

  before do
    # Generate ServiceHistoryEnrollment records from HUD records
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
  end

  let(:enrollment_hoh) { GrdaWarehouse::ServiceHistoryEnrollment.find_by(enrollment_group_id: hud_enrollment_hoh.EnrollmentID) }
  let(:enrollment_child) { GrdaWarehouse::ServiceHistoryEnrollment.find_by(enrollment_group_id: hud_enrollment_child.EnrollmentID) }

  subject(:builder) { described_class.new(generator, report) }

  describe '#build!' do
    it 'creates a context for each enrollment in the household' do
      expect { builder.build! }.to change(HudReports::HouseholdContext, :count).by(2)
    end

    it 'assigns correct household attributes' do
      builder.build!
      contexts = HudReports::HouseholdContext.where(household_id: 'HH123')

      expect(contexts.count).to eq(2)
      expect(contexts.pluck(:household_type).uniq).to eq(['adults_and_children'])
      expect(contexts.pluck(:member_count).uniq).to eq([2])
    end

    it 'identifies the Head of Household' do
      builder.build!
      hoh_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_hoh.id)
      child_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_child.id)

      expect(hoh_context.is_hoh).to be true
      expect(child_context.is_hoh).to be false
      expect(child_context.hoh_id).to eq(client_hoh.destination_client.id)
    end

    it 'updates the report instance count' do
      builder.build!
      expect(report.reload.household_context_count).to eq(2)
    end

    context 'when re-running (idempotency)' do
      before do
        create(:hud_reports_household_context, report_instance: report)
      end

      it 'clears previous contexts' do
        expect { builder.build! }.to change(HudReports::HouseholdContext, :count).from(1).to(2)
      end
    end

    context 'with chronic status inheritance' do
      before do
        # Mark HoH as chronic in source data
        hud_enrollment_hoh.update!(
          DisablingCondition: 1,
          ContinuouslyHomelessOneYear: 1,
          TimesHomelessPastThreeYears: 4,
          MonthsHomelessPastThreeYears: 112 # 112 = 12 months
        )
        # Re-rebuild to pick up changes
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(hud_enrollment_hoh.id).create_service_history!(true)
      end

      it 'passes chronic status from HoH to the child' do
        builder.build!
        child_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_child.id)
        expect(child_context.inherited_chronic_status).to be true
      end
    end

    context 'with synthetic household IDs' do
      let(:generator_synthetic) do
        instance_double(
          HudReports::GeneratorBase,
          client_scope: GrdaWarehouse::Hud::Client.where(id: [client_hoh.destination_client.id]),
          report_scope_source: GrdaWarehouse::ServiceHistoryEnrollment.entry
        )
      end

      before do
        # Remove household_id from HUD enrollment and rebuild
        hud_enrollment_hoh.update!(HouseholdID: nil)
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(hud_enrollment_hoh.id).create_service_history!(true)
      end

      it 'generates a synthetic ID using enrollment_group_id' do
        described_class.new(generator_synthetic, report).build!
        expect(HudReports::HouseholdContext.last.household_id).to eq("#{hud_enrollment_hoh.EnrollmentID}*HH")
      end
    end

    context 'with parenting youth' do
      let(:youth_hoh) { create_client_with_warehouse_link(dob: 20.years.ago) }
      let(:child) { create_client_with_warehouse_link(dob: 2.years.ago) }

      let!(:hud_enrollment_youth) do
        create(:hud_enrollment,
               PersonalID: youth_hoh.PersonalID,
               ProjectID: project.ProjectID,
               HouseholdID: 'HH-YOUTH',
               RelationshipToHoH: 1,
               EntryDate: '2020-01-01',
               data_source_id: data_source.id)
      end

      let!(:hud_enrollment_child_2) do
        create(:hud_enrollment,
               PersonalID: child.PersonalID,
               ProjectID: project.ProjectID,
               HouseholdID: 'HH-YOUTH',
               RelationshipToHoH: 2,
               EntryDate: '2020-01-01',
               data_source_id: data_source.id)
      end

      before do
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where(id: [hud_enrollment_youth.id, hud_enrollment_child_2.id]).each(&:rebuild_service_history!)
      end

      let(:enrollment_youth) { GrdaWarehouse::ServiceHistoryEnrollment.find_by(enrollment_group_id: hud_enrollment_youth.EnrollmentID) }

      let(:generator_youth) do
        instance_double(
          HudReports::GeneratorBase,
          client_scope: GrdaWarehouse::Hud::Client.where(id: [youth_hoh.destination_client.id, child.destination_client.id]),
          report_scope_source: GrdaWarehouse::ServiceHistoryEnrollment.entry
        )
      end

      it 'identifies the HoH as a parenting youth' do
        described_class.new(generator_youth, report).build!
        youth_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_youth.id)
        expect(youth_context.is_parenting_youth).to be true
      end
    end
  end
end
