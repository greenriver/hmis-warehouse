module BuiltForZeroReport
  def self.table_name_prefix
    'built_for_zero_report_'
  end

  def self.sections
    {
      veterans: 'Veterans Section',
      chronic: 'Chronic Section',
      adults: 'All Single Adults (Individuals) Section',
      youth: 'Youth Section',
      families: 'Family Section',
    }.invert.freeze
  end
end
