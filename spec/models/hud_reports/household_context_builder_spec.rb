# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::HouseholdContextBuilder, type: :model do
  let(:report) { create(:hud_reports_report_instance, start_date: '2020-01-01', end_date: '2020-12-31') }
  let(:generator) do
    instance_double(
      HudReports::GeneratorBase,
      client_scope: GrdaWarehouse::Hud::Client.all,
      report_scope_source: GrdaWarehouse::ServiceHistoryEnrollment.entry,
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

  describe '#call' do
    it 'creates a context for each enrollment in the household' do
      expect { builder.call }.to change(HudReports::HouseholdContext, :count).by(2)
    end

    it 'assigns correct household attributes' do
      builder.call
      contexts = HudReports::HouseholdContext.where(household_id: 'HH123')

      expect(contexts.count).to eq(2)
      expect(contexts.pluck(:household_type).uniq).to eq(['adults_and_children'])
      expect(contexts.pluck(:member_count).uniq).to eq([2])
    end

    it 'identifies the Head of Household' do
      builder.call
      hoh_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_hoh.id)
      child_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_child.id)

      expect(hoh_context.is_hoh).to be true
      expect(child_context.is_hoh).to be false
      expect(child_context.hoh_id).to eq(client_hoh.destination_client.id)
    end

    it 'updates the report instance count' do
      builder.call
      expect(report.reload.household_context_count).to eq(2)
    end

    context 'when re-running (idempotency)' do
      before do
        create(:hud_reports_household_context, report_instance: report)
      end

      it 'clears previous contexts' do
        expect { builder.call }.to change(HudReports::HouseholdContext, :count).from(1).to(2)
      end
    end

    context 'with chronic status inheritance' do
      before do
        # Mark HoH as chronic in source data
        hud_enrollment_hoh.update!(
          DisablingCondition: 1,
          ContinuouslyHomelessOneYear: 1,
          TimesHomelessPastThreeYears: 4,
          MonthsHomelessPastThreeYears: 112, # 112 = 12 months
        )
        # Re-rebuild to pick up changes
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(hud_enrollment_hoh.id).create_service_history!(true)
      end

      it 'passes chronic status from HoH to the child' do
        builder.call
        child_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_child.id)
        expect(child_context.inherited_chronic_status).to be true
      end

      it 'passes chronic status from another adult to the child if HoH is not chronic' do
        # HoH not chronic
        hud_enrollment_hoh.update!(DisablingCondition: 0)
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(hud_enrollment_hoh.id).create_service_history!(true)

        # Add another adult who is chronic
        adult_2 = create_client_with_warehouse_link(dob: 30.years.ago)
        create(:hud_enrollment,
               PersonalID: adult_2.PersonalID,
               ProjectID: project.ProjectID,
               HouseholdID: 'HH123',
               RelationshipToHoH: 3, # Spouse/Partner
               EntryDate: '2020-01-01',
               DisablingCondition: 1,
               ContinuouslyHomelessOneYear: 1,
               TimesHomelessPastThreeYears: 4,
               MonthsHomelessPastThreeYears: 112,
               data_source_id: data_source.id)

        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

        builder.call
        child_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_child.id)
        expect(child_context.inherited_chronic_status).to be true
      end

      it 'passes indeterminate chronic status (DK/R) from HoH to the child' do
        # HoH has DK/R
        hud_enrollment_hoh.update!(DisablingCondition: 8) # 8 = DK
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(hud_enrollment_hoh.id).create_service_history!(true)

        builder.call
        child_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_child.id)
        expect(child_context.inherited_chronic_detail).to eq('dk_or_r')
      end
    end

    context 'with move-in date inheritance' do
      before do
        hud_enrollment_hoh.update!(MoveInDate: '2020-06-01')
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(hud_enrollment_hoh.id).create_service_history!(true)
      end

      it 'inherits HoH move-in date when member is present' do
        builder.call
        child_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_child.id)
        expect(child_context.inherited_move_in_date).to eq(Date.parse('2020-06-01'))
      end

      it 'uses own entry date when joining after HoH move-in' do
        # Child joins in July
        hud_enrollment_child.update!(EntryDate: '2020-07-01')
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(hud_enrollment_child.id).create_service_history!(true)

        builder.call
        child_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_child.id)
        expect(child_context.inherited_move_in_date).to eq(Date.parse('2020-07-01'))
      end
    end

    context 'with different household types' do
      it 'identifies adults only households' do
        # Remove child and add another adult
        hud_enrollment_child.destroy
        adult_2 = create_client_with_warehouse_link(dob: 30.years.ago)
        create(:hud_enrollment,
               PersonalID: adult_2.PersonalID,
               ProjectID: project.ProjectID,
               HouseholdID: 'HH123',
               RelationshipToHoH: 3,
               EntryDate: '2020-01-01',
               data_source_id: data_source.id)

        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

        builder.call
        expect(HudReports::HouseholdContext.pluck(:household_type).uniq).to eq(['adults_only'])
      end

      it 'identifies children only households' do
        # Change HoH to child
        child_2 = create_client_with_warehouse_link(dob: 12.years.ago)
        hud_enrollment_hoh.update!(PersonalID: child_2.PersonalID)
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

        builder.call
        expect(HudReports::HouseholdContext.pluck(:household_type).uniq).to eq(['children_only'])
      end
    end

    context 'with synthetic household IDs' do
      let(:generator_synthetic) do
        instance_double(
          HudReports::GeneratorBase,
          client_scope: GrdaWarehouse::Hud::Client.where(id: [client_hoh.destination_client.id]),
          report_scope_source: GrdaWarehouse::ServiceHistoryEnrollment.entry,
        )
      end

      before do
        # Remove household_id from HUD enrollment and rebuild
        hud_enrollment_hoh.update!(HouseholdID: nil)
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(hud_enrollment_hoh.id).create_service_history!(true)
      end

      it 'generates a synthetic ID using enrollment_group_id' do
        described_class.new(generator_synthetic, report).call
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
          report_scope_source: GrdaWarehouse::ServiceHistoryEnrollment.entry,
        )
      end

    it 'identifies the HoH as a parenting youth' do
        described_class.new(generator_youth, report).call
        youth_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_youth.id)
        expect(youth_context.is_parenting_youth).to be true
      end

      it 'does not identify as parenting youth if there is a member over 25' do
        # Add a 40 year old member
        adult_over_25 = create_client_with_warehouse_link(dob: 40.years.ago)
        create(:hud_enrollment,
               PersonalID: adult_over_25.PersonalID,
               ProjectID: project.ProjectID,
               HouseholdID: 'HH-YOUTH',
               RelationshipToHoH: 3,
               EntryDate: '2020-01-01',
               data_source_id: data_source.id)

        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

        described_class.new(generator, report).call
        youth_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_youth.id)
        expect(youth_context.is_parenting_youth).to be false
        expect(youth_context.has_other_clients_over_25).to be true
      end
    end

    describe 'HouseholdQueryService' do
      let(:service) { HudReports::HouseholdQueryService.new(report, GrdaWarehouse::ServiceHistoryEnrollment.arel_table) }

      before { builder.call }

      it 'joins household context correctly' do
        scope = service.with_household_context(GrdaWarehouse::ServiceHistoryEnrollment.entry)
        expect(scope.to_sql).to include('INNER JOIN hud_report_household_contexts AS hh_ctx')
        expect(scope.to_sql).to include("hh_ctx.report_instance_id = #{report.id}")
      end

      it 'provides correct sub-population clauses' do
        expect(service.sub_populations['Without Children'].to_sql).to include('"hh_ctx"."household_type" = \'adults_only\'')
        expect(service.sub_populations['Chronically Homeless'].to_sql).to match(/"hh_ctx"\."inherited_chronic_status" = (true|TRUE)/)
      end
    end
  end
end
