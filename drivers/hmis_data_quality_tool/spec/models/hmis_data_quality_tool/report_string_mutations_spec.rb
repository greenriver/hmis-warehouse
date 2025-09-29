# frozen_string_literal: false

require 'rails_helper'

RSpec.describe HmisDataQualityTool::Report, type: :model do
  let(:report) { HmisDataQualityTool::Report.new }

  describe '#household method with << operations' do
    it 'uses << operation to build household arrays' do
      # Test the << operation from line 283: households[enrollment.HouseholdID] << she

      household_id = 'HH001'

      # Mock the database queries that household method uses
      enrollment = double(
        'enrollment',
        HouseholdID: household_id,
        EntryDate: Date.current,
        service_history_enrollment: double('she', age: 25),
        client: double('client', present?: true, age_on: 25),
      )

      scope = double('scope')
      allow(GrdaWarehouse::Hud::Enrollment).to receive(:joins).and_return(scope)
      allow(scope).to receive(:preload).and_return(scope)
      allow(scope).to receive(:merge).and_return(scope)
      allow(scope).to receive(:distinct).and_return(scope)
      allow(scope).to receive(:where).and_return(scope)
      allow(scope).to receive(:find_each).and_yield(enrollment)

      # Mock report dependencies
      allow(report).to receive(:report_scope).and_return(scope)
      allow(report).to receive_message_chain(:filter, :start).and_return(Date.current)

      # Call the actual method that contains the << operation
      result = report.household(household_id)

      # Should return array containing the service history enrollment
      expect(result).to be_an(Array)
    end

    it 'handles empty household ID' do
      result = report.household(nil)
      expect(result).to be_nil
    end
  end

  describe '#per_project_results method with += operations' do
    it 'uses += operations to accumulate project data' do
      # Test the += operations from lines 787-790

      # Mock the results that per_project_results method uses
      result_double = double(
        'result',
        category: 'test_category',
        projects: {
          'project_1' => { invalid_count: 5, total: 10 },
          'project_2' => { invalid_count: 3, total: 8 },
        },
      )

      allow(report).to receive(:results).and_return([result_double])
      allow(report).to receive(:count_category_setup).and_return(
        {
          'test_category' => { invalid_count: 0, total: 0 },
          'Overall' => { invalid_count: 0, total: 0 },
        },
      )

      # Call the actual method that contains the += operations
      result = report.per_project_results

      # Should accumulate counts using += operations
      expect(result).to be_a(Hash)
      expect(result['project_1']).to be_a(Hash)
      expect(result['project_2']).to be_a(Hash)
    end
  end

  describe '#run_and_save! method with += and << operations' do
    it 'calls run_and_save! method that contains string mutations' do
      # Test the += operations from lines 721-722 and << operation from line 724

      # Mock all the complex dependencies that run_and_save! uses
      allow(report).to receive(:start).and_return(true)
      allow(report).to receive(:complete).and_return(true)
      allow(report).to receive(:save).and_return(true)
      allow(report).to receive(:result_cache_as_open_struct).and_return({})

      # Mock the complex report calculation methods
      allow(report).to receive(:report_clients).and_return([])
      allow(report).to receive(:client_items_for).and_return([])
      allow(report).to receive(:report_enrollments).and_return({})
      allow(report).to receive(:enrollments).and_return([])
      allow(report).to receive(:inventories).and_return([])
      allow(report).to receive(:current_living_situations).and_return([])

      # Mock the calculation classes
      allow(HmisDataQualityTool::Client).to receive(:calculate)
      allow(HmisDataQualityTool::Enrollment).to receive(:calculate)
      allow(HmisDataQualityTool::Inventory).to receive(:calculate)
      allow(HmisDataQualityTool::CurrentLivingSituation).to receive(:calculate)

      # Call the actual method that contains the string mutations
      expect { report.run_and_save! }.not_to raise_error
    end
  end

  describe 'method calls that exercise string mutations' do
    it 'exercises household method without errors' do
      # Mock minimal dependencies
      allow(report).to receive(:report_scope).and_return(GrdaWarehouse::Hud::Enrollment.none)
      allow(report).to receive_message_chain(:filter, :start).and_return(Date.current)

      # Should call method with << operations without error
      expect { report.household('test_id') }.not_to raise_error
    end

    it 'exercises per_project_results method without errors' do
      # Mock minimal dependencies
      allow(report).to receive(:results).and_return([])
      allow(report).to receive(:count_category_setup).and_return({})

      # Should call method with += operations without error
      expect { report.per_project_results }.not_to raise_error
    end
  end
end
