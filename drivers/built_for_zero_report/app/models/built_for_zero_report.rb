module BuiltForZeroReport
  def self.table_name_prefix
    'built_for_zero_report_'
  end

  def self.all_report_sections
    {
      veterans: 'Veterans Section',
      chronic_veterans: 'Chronic Veterans Section',
      chronic: 'Chronic Section',
      adults: 'All Single Adults (Individuals) Section',
      youth: 'Youth Section',
      families: 'Family Section',
    }
  end

  def self.sections
    return {} unless ::GrdaWarehouse::Config.get(:enable_system_cohorts)

    cohort_keys = {
      veterans: :veteran_cohort,
      chronic_veterans: :chronic_cohort,
      chronic: :chronic_cohort,
      adults: :adult_only_cohort,
      youth: :youth_cohort,
      families: :adult_and_child_cohort,
    }.freeze

    all_report_sections.
      select do |k, _|
        ::GrdaWarehouse::SystemCohorts::Base.find_system_cohort(cohort_keys[k]).present? &&
        ::GrdaWarehouse::Config.get(cohort_keys[k])
      end.
      invert.
      freeze
  end
end
