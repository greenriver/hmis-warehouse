###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Cohorts::RepairColumnState do
  let!(:cohort) { create :cohort }

  def poison_column_state!(cohort, columns)
    columns.each(&:cohort_column)
    raw = YAML.dump(columns)
    cohort.class.connection.execute(
      "UPDATE cohorts SET column_state = #{cohort.class.connection.quote(raw)} WHERE id = #{cohort.id}",
    )
  end

  context 'when column_state carries a leaked GrdaWarehouse::Cohorts::CohortColumn instance' do
    before do
      poison_column_state!(cohort, [build(:user_string_cohort_column_1), build(:user_string_cohort_column_2)])
    end

    it 'raises Psych::DisallowedClass before repair' do
      expect { cohort.reload.column_state }.to raise_error(Psych::DisallowedClass)
    end

    it 'strips the leaked instance so column_state deserializes cleanly' do
      described_class.run!

      expect(cohort.reload.column_state.map(&:class_name)).to match_array(['CohortColumns::UserString1', 'CohortColumns::UserString2'])
    end

    it 'clears the memoized cohort_column so it can be looked up fresh' do
      described_class.run!

      cohort.reload.column_state.each do |col|
        expect(col.instance_variable_defined?(:@cohort_column)).to be false
      end
    end
  end

  context 'when column_state is already clean' do
    let!(:clean_columns) { [build(:user_string_cohort_column_1)] }

    before { cohort.update!(column_state: clean_columns) }

    it 'leaves it unchanged' do
      described_class.run!

      expect(cohort.reload.column_state.map(&:class_name)).to eq(['CohortColumns::UserString1'])
    end
  end

  context 'when column_state is blank' do
    before { cohort.update!(column_state: []) }

    it 'does not raise' do
      expect { described_class.run! }.not_to raise_error
    end
  end

  context 'with a mix of poisoned and clean cohorts' do
    let!(:clean_cohort) { create :cohort, column_state: [build(:user_string_cohort_column_1)] }

    before { poison_column_state!(cohort, [build(:user_string_cohort_column_2)]) }

    it 'repairs the poisoned cohort and leaves the clean one untouched' do
      described_class.run!

      expect(cohort.reload.column_state.map(&:class_name)).to eq(['CohortColumns::UserString2'])
      expect(clean_cohort.reload.column_state.map(&:class_name)).to eq(['CohortColumns::UserString1'])
    end
  end
end
