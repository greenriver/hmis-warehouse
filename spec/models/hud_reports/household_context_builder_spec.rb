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

      # Verify new pre-computed fields
      contexts.each do |ctx|
        expect(ctx.age).to be_present
        expect(ctx.hoh_entry_date).to eq(Date.parse('2020-01-01'))
        expect(ctx.hoh_coc).to be_present
      end
    end

    it 'identifies the Head of Household' do
      builder.call
      hoh_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_hoh.id)
      child_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_child.id)

      expect(hoh_context.is_hoh).to be true
      expect(child_context.is_hoh).to be false
      expect(child_context.hoh_destination_client_id).to eq(client_hoh.destination_client.id)
      expect(child_context.hoh_entry_date).to eq(hoh_context.service_history_enrollment.first_date_in_program)
    end

    it 'updates the report instance count' do
      builder.call
      expect(report.reload.household_context_count).to eq(2)
    end

    context 'when re-running (idempotency)' do
      before do
        create(:hud_reports_household_context,report_instance: report)
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
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(hud_enrollment_hoh.id).rebuild_service_history!
      end

      it 'passes chronic status from HoH to the child' do
        builder.call
        child_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_child.id)
        expect(child_context.inherited_chronic_status).to be true
      end

      it 'passes chronic status from another adult to the child if HoH is not chronic' do
        # HoH not chronic
        hud_enrollment_hoh.update!(DisablingCondition: 0)
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(hud_enrollment_hoh.id).rebuild_service_history!

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
        expect(child_context.hoh_move_in_date).to eq(Date.parse('2020-06-01'))
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
        GrdaWarehouse::ServiceHistoryEnrollment.where(enrollment_group_id: hud_enrollment_child.EnrollmentID).delete_all
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
        GrdaWarehouse::ServiceHistoryEnrollment.where(enrollment_group_id: hud_enrollment_hoh.EnrollmentID).delete_all
        hud_enrollment_hoh.destroy

        child_2 = create_client_with_warehouse_link(dob: 12.years.ago)
        create(:hud_enrollment,
               PersonalID: child_2.PersonalID,
               ProjectID: project.ProjectID,
               HouseholdID: 'HH123',
               RelationshipToHoH: 1,
               EntryDate: '2020-01-01',
               data_source_id: data_source.id)

        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

        builder.call
        expect(HudReports::HouseholdContext.pluck(:household_type).uniq).to eq(['children_only'])
      end

      it 'categorizes as unknown if an adult household has a member with a missing DOB' do
        # Remove the child and add an adult with no DOB
        GrdaWarehouse::ServiceHistoryEnrollment.where(enrollment_group_id: hud_enrollment_child.EnrollmentID).delete_all
        hud_enrollment_child.destroy
        unknown_adult = create_client_with_warehouse_link(dob: nil)
        create(:hud_enrollment,
               PersonalID: unknown_adult.PersonalID,
               ProjectID: project.ProjectID,
               HouseholdID: 'HH123',
               RelationshipToHoH: 3,
               EntryDate: '2020-01-01',
               data_source_id: data_source.id)

        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

        builder.call
        # One 40yo adult + one unknown = unknown type
        expect(HudReports::HouseholdContext.pluck(:household_type).uniq).to eq(['unknown'])
      end

      it 'categorizes as unknown if a child household has a member with a missing DOB' do
        # Change HoH to child and remove the adult HoH
        GrdaWarehouse::ServiceHistoryEnrollment.where(enrollment_group_id: hud_enrollment_hoh.EnrollmentID).delete_all
        hud_enrollment_hoh.destroy

        child_2 = create_client_with_warehouse_link(dob: 12.years.ago)
        create(:hud_enrollment,
               PersonalID: child_2.PersonalID,
               ProjectID: project.ProjectID,
               HouseholdID: 'HH123',
               RelationshipToHoH: 1,
               EntryDate: '2020-01-01',
               data_source_id: data_source.id)

        # Child 10yo (from let) + Child 12yo + Unknown age member
        unknown_member = create_client_with_warehouse_link(dob: nil)
        create(:hud_enrollment,
               PersonalID: unknown_member.PersonalID,
               ProjectID: project.ProjectID,
               HouseholdID: 'HH123',
               RelationshipToHoH: 3,
               EntryDate: '2020-01-01',
               data_source_id: data_source.id)

        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

        builder.call
        expect(HudReports::HouseholdContext.pluck(:household_type).uniq).to eq(['unknown'])
      end

      it 'still categorizes as adults_and_children if both are present even with an unknown age member' do
        # HoH (40yo) + Child (10yo) + Unknown age member
        unknown_member = create_client_with_warehouse_link(dob: nil)
        create(:hud_enrollment,
               PersonalID: unknown_member.PersonalID,
               ProjectID: project.ProjectID,
               HouseholdID: 'HH123',
               RelationshipToHoH: 3,
               EntryDate: '2020-01-01',
               data_source_id: data_source.id)

        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

        builder.call
        # Adults + Children present, so it's known even if one member is missing DOB
        expect(HudReports::HouseholdContext.pluck(:household_type).uniq).to eq(['adults_and_children'])
      end
    end

    context 'with hoh_date_to_street' do
      before do
        hud_enrollment_hoh.update!(DateToStreetESSH: '2019-12-01')
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(hud_enrollment_hoh.id).create_service_history!(true)
      end

      it 'populates hoh_date_to_street' do
        builder.call
        child_context = HudReports::HouseholdContext.find_by(service_history_enrollment_id: enrollment_child.id)
        expect(child_context.hoh_date_to_street).to eq(Date.parse('2019-12-01'))
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

    describe 'context copying from source report' do
      let(:user) { create(:user) }
      let(:start_date) { Date.parse('2020-01-01') }
      let(:end_date) { Date.parse('2020-12-31') }
      let(:source_report) { create(:hud_reports_report_instance, user: user, start_date: start_date, end_date: end_date) }
      let(:target_report) { create(:hud_reports_report_instance, user: user, start_date: start_date, end_date: end_date) }

      # Create a simple test generator class to avoid instance_double issues
      let(:test_generator_class) do
        Class.new(HudReports::GeneratorBase) do
          attr_accessor :client_scope_override
          def client_scope(...)
            client_scope_override || super
          end

          def self.filter_class
            ::Filters::HudFilterBase
          end
        end
      end
      let(:source_generator) do
        test_generator_class.new(source_report).tap do |g|
          g.client_scope_override = GrdaWarehouse::Hud::Client.all
        end
      end

      before do
        # Create contexts in source report
        builder = described_class.new(source_generator, source_report)
        builder.call
      end

      it 'copies relevant contexts from source report' do
        # Target report has subset of projects
        target_generator = test_generator_class.new(target_report)
        target_generator.client_scope_override = GrdaWarehouse::Hud::Client.where(id: client_hoh.destination_client.id)

        builder = described_class.new(target_generator, target_report, source_report_id: source_report.id)
        builder.call

        # Verify contexts were copied with new report_instance_id
        expect(target_report.reload.household_contexts.count).to be > 0
        expect(target_report.household_contexts.pluck(:report_instance_id).uniq).to eq([target_report.id])

        # Verify context data matches source
        source_ctx = source_report.reload.household_contexts.first
        target_ctx = target_report.household_contexts.find_by(service_history_enrollment_id: source_ctx.service_history_enrollment_id)
        expect(target_ctx.inherited_chronic_status).to eq(source_ctx.inherited_chronic_status)
        expect(target_ctx.inherited_move_in_date).to eq(source_ctx.inherited_move_in_date)
      end

      it 'raises error if date ranges do not match' do
        mismatched_report = create(:hud_reports_report_instance,
                                   start_date: start_date + 1.day,
                                   end_date: end_date)

        builder = described_class.new(source_generator, mismatched_report, source_report_id: source_report.id)

        expect { builder.call }.to raise_error(ArgumentError, /date ranges don't match/)
      end

      it 'handles empty result set gracefully' do
        empty_generator = test_generator_class.new(target_report)
        empty_generator.client_scope_override = GrdaWarehouse::Hud::Client.none

        builder = described_class.new(empty_generator, target_report, source_report_id: source_report.id)
        builder.call

        expect(target_report.household_contexts.count).to eq(0)
      end
    end

    context 'with custom enrollment_scope' do
      let(:custom_scope) { GrdaWarehouse::ServiceHistoryEnrollment.where(id: [enrollment_hoh.id]) }

      it 'uses provided scope instead of generator discovery' do
        builder = described_class.new(generator, report, enrollment_scope: custom_scope)
        builder.call

        # Should only build context for enrollments in custom scope
        report.reload
        expect(report.household_contexts.count).to eq(1)
        expect(report.household_contexts.first.service_history_enrollment_id).to eq(enrollment_hoh.id)
      end
    end
  end
end
