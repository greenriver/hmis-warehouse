# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Cohorts::CohortColumn, type: :model do
  let!(:cohort) { create :cohort }
  let!(:cohort_column) { build :user_string_cohort_column_1 }

  before(:all) do
    GrdaWarehouse::Cohorts::CohortColumn.maintain!
  end

  describe 'active scope' do
    it 'returns only active columns' do
      inactive_column = build :user_string_cohort_column_2
      inactive_column.cohort_column.deactivate

      expect(described_class.active.to_a.map(&:class_name)).to include(cohort_column.class_name)
      expect(described_class.active.to_a.map(&:class_name)).not_to include(inactive_column.class_name)
    end
  end

  describe 'active flag changes' do
    it 'affects available_columns' do
      expect(GrdaWarehouse::Cohort.active_columns.map(&:class_name)).to include('CohortColumns::UserString1')

      cohort_column.cohort_column.deactivate
      expect(GrdaWarehouse::Cohort.active_columns.map(&:class_name)).not_to include('CohortColumns::UserString1')
    end
  end
end
