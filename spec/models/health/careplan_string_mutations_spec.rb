# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Health::Careplan, type: :model do
  let(:user) { create(:user) }
  let(:patient) { create(:patient) }
  let(:careplan) { create(:careplan, patient: patient, user: user) }

  describe 'string mutation operations' do
    describe '#compact_future_issues with << operation' do
      it 'compacts future issues using << operator when moving non-blank values' do
        # Test the string mutation from line 381: issues << self["future_issues_#{i}"].presence

        # Set up some future issues with blanks mixed in
        careplan.update(
          future_issues_0: 'First issue',
          future_issues_1: '',
          future_issues_2: nil,
          future_issues_3: 'Second issue',
          future_issues_4: '   ', # whitespace only
          future_issues_5: 'Third issue',
          future_issues_6: nil,
          future_issues_7: '',
          future_issues_8: nil,
          future_issues_9: nil,
          future_issues_10: 'Last issue',
        )

        careplan.compact_future_issues

        # Verify that the << operation worked correctly - should compact non-blank values to the beginning
        expect(careplan.future_issues_0).to eq('First issue')
        expect(careplan.future_issues_1).to eq('Second issue')
        expect(careplan.future_issues_2).to eq('Third issue')
        expect(careplan.future_issues_3).to eq('Last issue')

        # The rest should be nil after compaction
        expect(careplan.future_issues_4).to be_nil
        expect(careplan.future_issues_5).to be_nil
        expect(careplan.future_issues_6).to be_nil
        expect(careplan.future_issues_7).to be_nil
        expect(careplan.future_issues_8).to be_nil
        expect(careplan.future_issues_9).to be_nil
        expect(careplan.future_issues_10).to be_nil
      end

      it 'handles case where all future issues are blank' do
        # Set all future issues to blank values
        11.times do |i|
          careplan.send("future_issues_#{i}=", ['', nil, '  '].sample)
        end

        careplan.compact_future_issues

        # All should be nil after compaction since none had presence
        11.times do |i|
          expect(careplan.send("future_issues_#{i}")).to be_nil
        end
      end

      it 'handles case where all future issues are already compacted' do
        # Set up already compacted issues
        careplan.update(
          future_issues_0: 'Issue 1',
          future_issues_1: 'Issue 2',
          future_issues_2: 'Issue 3',
          # rest are nil
        )

        original_values = []
        11.times do |i|
          original_values[i] = careplan.send("future_issues_#{i}")
        end

        careplan.compact_future_issues

        # Should remain the same since already compacted
        11.times do |i|
          expect(careplan.send("future_issues_#{i}")).to eq(original_values[i])
        end
      end

      it 'preserves issue content during compaction' do
        # Test with various content types including strings with special characters
        special_issue = "Issue with 'quotes' and \"double quotes\" and \n newlines"

        careplan.update(
          future_issues_0: nil,
          future_issues_1: special_issue,
          future_issues_2: '',
          future_issues_3: 'Simple issue',
          future_issues_4: nil,
        )

        careplan.compact_future_issues

        expect(careplan.future_issues_0).to eq(special_issue)
        expect(careplan.future_issues_1).to eq('Simple issue')
        expect(careplan.future_issues_2).to be_nil
        expect(careplan.future_issues_3).to be_nil
        expect(careplan.future_issues_4).to be_nil
      end

      it 'handles maximum number of issues correctly' do
        # Fill all 11 slots with issues
        11.times do |i|
          careplan.send("future_issues_#{i}=", "Issue #{i + 1}")
        end

        careplan.compact_future_issues

        # All should remain in place since no compaction needed
        11.times do |i|
          expect(careplan.send("future_issues_#{i}")).to eq("Issue #{i + 1}")
        end
      end
    end

    describe '#future_issues? method interaction' do
      it 'works correctly with compacted issues' do
        careplan.update(
          future_issues_0: '',
          future_issues_1: nil,
          future_issues_2: 'Real issue',
          future_issues_3: '',
          future_issues_4: 'Another issue',
        )

        # Before compaction, should find issues
        expect(careplan.future_issues?).to be_truthy

        careplan.compact_future_issues

        # After compaction, should still find issues
        expect(careplan.future_issues?).to be_truthy
        expect(careplan.future_issues_0).to eq('Real issue')
        expect(careplan.future_issues_1).to eq('Another issue')
      end

      it 'returns false when no real issues after compaction' do
        careplan.update(
          future_issues_0: '',
          future_issues_1: nil,
          future_issues_2: '   ', # only whitespace
          future_issues_3: '',
        )

        careplan.compact_future_issues

        expect(careplan.future_issues?).to be_falsey
      end
    end
  end
end
