# frozen_string_literal: true

class Hmis::TableConfiguration < Hmis::HmisBase
  CONSOLIDATED_WAITLIST = 'consolidated_waitlist'
  TABLE_KEYS = [
    CONSOLIDATED_WAITLIST,
  ].freeze

  belongs_to :owner, polymorphic: true, optional: true

  validates :table_key, inclusion: { in: TABLE_KEYS }
  validates :table_key, presence: true, uniqueness: { scope: [:owner_type, :owner_id], message: 'must be unique per owner' }

  validate :validate_columns_shape
  validate :validate_filters_shape

  FILTER_TYPES = [
    'dropdown',
    'date',
  ].freeze

  def self.for_consolidated_waitlist(data_source_id:)
    find_by(table_key: CONSOLIDATED_WAITLIST, data_source_id: data_source_id, owner: nil) # consolidated waitlist is global
  end

  # example columns: [{"key": "cde.custom_assessment.hna_ce_test_1_prioritization_score", "label": "AHA Score"}, {"key": "cde.custom_assessment.hna_ce_test_1_household_type", "label": "Household Type"}]

  # example filters: [{"key": "cde.custom_assessment.hna_ce_test_1_prioritization_score", "label": "Score", "values": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]}]

  private

  # [
  #   {
  #     "key": "cde.custom_assessment.hna_ce_test_1_prioritization_score",
  #     "label": "My Score"
  #   },
  #   {
  #     "key": "cde.custom_assessment.hna_ce_test_1_household_type",
  #     "label": "Household Type"
  #   }
  # ]
  def validate_columns_shape
    return if columns.is_a?(Array) && columns.all? { |col| col.is_a?(Hash) && col.key?('key') && col.key?('label') && col['key'].is_a?(String) && col['label'].is_a?(String) }

    errors.add(:columns, 'must be an array of hashes with keys "key" (string) and "label" (string)')
  end

  # [
  #   {
  #     "key": "cde.custom_assessment.hna_ce_test_1_prioritization_score",
  #     "label": "My Score",
  #     "options": [
  #       { "code": "1"},
  #       { "code": "2"},
  #       { "code": "3"},
  #       { "code": "4"},
  #       { "code": "5"},
  #       { "code": "6"},
  #       { "code": "7"},
  #       { "code": "8"},
  #       { "code": "9"},
  #       { "code": "10"}
  #     ]
  #   }
  # ]
  def validate_filters_shape
    return unless filters.is_a?(Array)

    filters.each do |filter|
      unless filter.is_a?(Hash)
        errors.add(:filters, 'each filter must be a hash')
        next
      end

      unless filter.key?('key') && filter['key'].is_a?(String)
        errors.add(:filters, 'each filter must have a "key" (string)')
        next
      end

      unless filter.key?('label') && filter['label'].is_a?(String)
        errors.add(:filters, 'each filter must have a "label" (string)')
        next
      end

      unless filter.key?('type') && filter['type'].is_a?(String) && FILTER_TYPES.include?(filter['type'])
        errors.add(:filters, 'each filter must have a "type" (string)')
        next
      end

      next unless filter['type'] == 'dropdown'

      unless filter.key?('options') && filter['options'].is_a?(Array)
        errors.add(:filters, 'dropdown filters must have an "options" array')
        next
      end

      filter['options'].each do |opt|
        next if opt.is_a?(Hash) && opt.key?('code') && opt['code'].is_a?(String)

        errors.add(:filters, 'each option in "options" must be a hash with "code" (string) and optional "label" (string)')
      end
    end
  end
end
