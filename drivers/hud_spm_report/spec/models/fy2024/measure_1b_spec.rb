
require 'rails_helper'

RSpec.describe HudSpmReport::Generators::Fy2024::MeasureOne, type: :model do
  describe '#run_1b' do
    let(:user) { create(:user) }
    let(:filter) do
      Filters::HudFilterBase.new(
        user_id: user.id,
        start: '2022-10-01'.to_date,
        end: '2023-09-30'.to_date,
        coc_codes: ['MA-500'],
        enforce_one_year_range: false
      )
    end

    let!(:destination_data_source) { create :destination_data_source }

    let(:data_source) { create(:source_data_source) }
    before do
      data_source = create(:source_data_source)
      @organization = create(:hud_organization, data_source: data_source)

      # Create a project that participates in CoC
      @project = create(:hud_project,
        ProjectType: 0, # ES
        organization: @organization,
        data_source: data_source,
        ContinuumProject: 1 # Important: This flags the project as participating in CoC
      )

      @project_coc = create(:hud_project_coc,
        ProjectID: @project.ProjectID,
        data_source: data_source,
        CoCCode: 'MA-500'
      )

      # Create client and warehouse client connection
      @client = create(:hud_client, PersonalID: SecureRandom.uuid, data_source: data_source)
      @destination_client = create(:hud_client, data_source: destination_data_source)
      create(:warehouse_client, destination_id: @destination_client.id, source_id: @client.id)

      # Create enrollment with head of household and prior homelessness date
      @enrollment = create(:hud_enrollment,
        PersonalID: @client.PersonalID,
        project: @project,
        data_source: data_source,
        EntryDate: '2022-11-01',
        DateToStreetESSH: '2022-10-15', # Prior homelessness date
        RelationshipToHoH: 1, # Critical: Head of Household
        HouseholdID: 'test_household_1'
      )

      # Add exit date
      create(:hud_exit,
        enrollment: @enrollment,
        ExitDate: '2023-01-15',
        data_source: data_source,
        PersonalID: @client.PersonalID,
      )

      # Update filter to include the project
      filter.update(project_ids: [@project.id])

      # Create the report
      @report = HudReports::ReportInstance.from_filter(
        filter,
        'System Performance Measures - FY 2024',
        build_for_questions: ['Measure 1']
      )
      @report.question_names = ['Measure 1']
      @report.save!

      # Build ServiceHistoryEnrollments
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each do |enrollment|
        enrollment.rebuild_service_history!
      end

      # Generate the SpmEnrollment records
      HudSpmReport::Fy2024::SpmEnrollment.create_enrollment_set(@report)
    end

    it 'creates SpmEnrollment records correctly' do
      # First, verify we have service history enrollments
      expect(GrdaWarehouse::ServiceHistoryEnrollment.count).to be > 0

      # Verify SpmEnrollment records were created
      expect(@report.spm_enrollments.count).to be > 0

      # Verify the enrollment data was captured correctly
      spm_enrollment = @report.spm_enrollments.first
      expect(spm_enrollment.entry_date).to eq('2022-11-01'.to_date)
      expect(spm_enrollment.exit_date).to eq('2023-01-15'.to_date)
      expect(spm_enrollment.start_of_homelessness).to eq('2022-10-15'.to_date)
    end

    it 'correctly calculates the length of time homeless including prior living situation' do
      generator = HudSpmReport::Generators::Fy2024::Generator.new(@report)
      measure = HudSpmReport::Generators::Fy2024::MeasureOne.new(generator, @report)

      # Run the measure
      measure.run_question!

      # Verify that the universe was created for measure 1b
      expect(@report.universe('m1b1').members.count).to eq(1)

      # Verify that the appropriate metrics were calculated
      answer_b1 = @report.answer(question: '1b', cell: 'B1')
      answer_d1 = @report.answer(question: '1b', cell: 'D1')
      answer_g1 = @report.answer(question: '1b', cell: 'G1')

      # Should have a count of 1 person
      expect(answer_b1.summary.to_i).to eq(1)

      # Should have calculated the average length of time
      expect(answer_d1.summary.to_f).to be > 0

      # Should have calculated the median length of time
      expect(answer_g1.summary.to_i).to be > 0

      # Verify that the self-reported homelessness date is included
      episode = @report.universe('m1b1').members.first.universe_membership
      expect(episode.first_date).to eq('2022-10-15'.to_date)

      # Expected days homeless: Oct 15 to Jan 15 = 93 days
      expect(episode.days_homeless).to eq(93)
    end
  end
end
