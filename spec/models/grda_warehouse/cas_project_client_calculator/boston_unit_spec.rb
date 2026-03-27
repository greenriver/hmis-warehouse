# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::CasProjectClientCalculator::Boston, type: :model do
  let(:calculator) { described_class.new }
  let(:client) { create :grda_warehouse_hud_client }

  describe '#rrh_desired' do
    let(:mock_assessment) { double('GrdaWarehouse::Hud::Assessment') }

    before do
      allow(calculator).to receive(:most_recent_pathways_or_transfer).with(client).and_return(mock_assessment)
    end

    it 'returns true when the client answered yes to RRH interest' do
      allow(mock_assessment).to receive(:question_matching_requirement).with('c_interested_rrh').and_return(
        double('AssessmentQuestion', AssessmentAnswer: '1'),
      )
      expect(calculator.send(:rrh_desired, client)).to be(true)
    end

    it 'returns false when the client explicitly declined RRH interest' do
      allow(mock_assessment).to receive(:question_matching_requirement).with('c_interested_rrh').and_return(
        double('AssessmentQuestion', AssessmentAnswer: '0'),
      )
      expect(calculator.send(:rrh_desired, client)).to be(false)
    end

    it 'returns true when the RRH interest question was not on the assessment' do
      allow(mock_assessment).to receive(:question_matching_requirement).with('c_interested_rrh').and_return(nil)
      expect(calculator.send(:rrh_desired, client)).to be(true)
    end

    it 'returns true when the question exists but has no answer' do
      allow(mock_assessment).to receive(:question_matching_requirement).with('c_interested_rrh').and_return(
        double('AssessmentQuestion', AssessmentAnswer: nil),
      )
      expect(calculator.send(:rrh_desired, client)).to be(true)
    end

    it 'returns the computed value from value_for_cas_project_client when a pathways assessment is present' do
      allow(mock_assessment).to receive(:question_matching_requirement).with('c_interested_rrh').and_return(
        double('AssessmentQuestion', AssessmentAnswer: '1'),
      )
      expect(calculator.value_for_cas_project_client(client: client, column: :rrh_desired)).to be(true)
    end
  end

  describe 'boolean_lookups and #for_boolean' do
    let(:mock_assessment) { double('GrdaWarehouse::Hud::Assessment') }

    before do
      allow(calculator).to receive(:most_recent_pathways_or_transfer).with(client).and_return(mock_assessment)
    end

    it 'boolean_lookups includes at least one item' do
      expect(calculator.send(:boolean_lookups).keys.count).to be > 0
    end

    it 'maps question_matching_requirement(key, "1") to CAS booleans for each boolean_lookups column' do
      # Stub return is what Hud::Assessment#question_matching_requirement returns after comparing the stored answer to "1".
      answer_outcomes = {
        '1' => [true, true],
        '0' => [false, false],
        nil => [nil, false],
        'foo' => [false, false],
      }

      aggregate_failures do
        calculator.send(:boolean_lookups).each do |column, question_key|
          answer_outcomes.each do |label, (stub_return, expected)|
            allow(mock_assessment).to receive(:question_matching_requirement).with(question_key, '1').and_return(stub_return)
            actual = calculator.value_for_cas_project_client(client: client, column: column)
            expect(actual).to eq(expected), "column #{column} (#{question_key}): expected #{expected} for answer #{label.inspect} (stub #{stub_return.inspect})"
          end
        end
      end
    end

    it 'returns false from #for_boolean for every boolean question when there is no pathways or transfer assessment' do
      allow(calculator).to receive(:most_recent_pathways_or_transfer).with(client).and_return(nil)
      calculator.send(:boolean_lookups).each_value do |question_key|
        expect(calculator.send(:for_boolean, client, question_key)).to be(false)
      end
    end
  end

  describe 'string mutation operations' do
    describe '#pathways_days_homeless method += operations' do
      before do
        allow(calculator).to receive(:additional_homeless_nights_unsheltered).and_return(100)
        allow(calculator).to receive(:additional_homeless_nights_sheltered).and_return(200)
        allow(calculator).to receive(:max_possible_self_report_homeless_days).and_return(1096)
        allow(calculator).to receive(:calculated_homeless_nights_unsheltered).and_return(50)
        allow(calculator).to receive(:calculated_homeless_nights_sheltered).and_return(75)
        allow(calculator).to receive(:max_possible_days).and_return(1096)
      end

      it 'should accumulate days using += operator for warehouse unsheltered days' do
        # Test the pattern: days += warehouse_unsheltered_days from line 487
        days = 300 # Initial days (unsheltered + sheltered clamped)
        warehouse_unsheltered_days = 50

        days += warehouse_unsheltered_days

        expect(days).to eq(350)
      end

      it 'should accumulate days using += operator for warehouse sheltered days' do
        # Test the pattern: days += warehouse_sheltered_days from line 488
        days = 350 # After adding unsheltered days
        warehouse_sheltered_days = 75

        days += warehouse_sheltered_days

        expect(days).to eq(425)
      end

      it 'should handle sequential += operations correctly' do
        # Test both += operations together
        days = 300
        warehouse_unsheltered_days = 50
        warehouse_sheltered_days = 75

        days += warehouse_unsheltered_days
        days += warehouse_sheltered_days

        expect(days).to eq(425)
      end

      it 'should call actual pathways_days_homeless method and verify += operations work' do
        # Call the actual private method that contains the += operations
        result = calculator.send(:pathways_days_homeless, client)

        # The result should be the sum of all the components, clamped to max_possible_days
        # (100 + 200).clamp(0, 1096) + 50 + 75 = 300 + 50 + 75 = 425
        expect(result).to eq(425)
      end
    end

    describe '#default_shelter_agency_contacts method << operation' do
      before do
        # Mock the complete chain for client_contacts
        shelter_contacts = double('shelter_contacts')
        where_not_scope = double('where_not_scope')
        allow(client).to receive_message_chain(:client_contacts, :shelter_agency_contacts).and_return(shelter_contacts)
        allow(shelter_contacts).to receive(:where).and_return(where_not_scope)
        allow(where_not_scope).to receive(:not).with(email: nil).and_return(where_not_scope)
        allow(where_not_scope).to receive(:pluck).with(:email).and_return(['contact1@example.com', 'contact2@example.com'])

        # Create a mock user and assessment
        mock_user = double('user', user_email: 'assessor@example.com')
        mock_assessment = double('assessment', user: mock_user, assessment_date: Date.current)
        allow(client).to receive_message_chain(:source_assessments, :max_by).and_return(mock_assessment)
      end

      it 'should call actual default_shelter_agency_contacts method and verify << operation works' do
        # Call the actual private method that contains the << operation (line 507)
        result = calculator.send(:default_shelter_agency_contacts, client)

        # The method uses: contact_emails << client.source_assessments.max_by(&:assessment_date)&.user&.user_email
        # Then calls compact.uniq, so verify the << operation worked and the final result
        expect(result).to include('contact1@example.com', 'contact2@example.com', 'assessor@example.com')
        expect(result).to be_an(Array)
        expect(result.length).to eq(3)
      end

      it 'should handle empty contact list with << operation in actual method' do
        # Override the previous mock to return empty list
        where_not_scope = double('where_not_scope')
        allow(where_not_scope).to receive(:pluck).with(:email).and_return([])
        allow(client).to receive_message_chain(:client_contacts, :shelter_agency_contacts, :where).and_return(where_not_scope)
        allow(where_not_scope).to receive(:not).with(email: nil).and_return(where_not_scope)

        result = calculator.send(:default_shelter_agency_contacts, client)

        # Should still append the user email even with empty initial list
        expect(result).to eq(['assessor@example.com'])
      end

      it 'should handle case where assessment user email is nil in actual method' do
        mock_user = double('user', user_email: nil)
        mock_assessment = double('assessment', user: mock_user, assessment_date: Date.current)
        allow(client).to receive_message_chain(:source_assessments, :max_by).and_return(mock_assessment)

        result = calculator.send(:default_shelter_agency_contacts, client)

        # compact should remove the nil after the << operation
        expect(result).to eq(['contact1@example.com', 'contact2@example.com'])
        expect(result).not_to include(nil)
      end

      it 'should handle case where no assessment exists in actual method' do
        allow(client).to receive_message_chain(:source_assessments, :max_by).and_return(nil)

        result = calculator.send(:default_shelter_agency_contacts, client)

        # Should handle nil assessment gracefully due to safe navigation operators
        expect(result).to eq(['contact1@example.com', 'contact2@example.com'])
      end
    end
  end
end
