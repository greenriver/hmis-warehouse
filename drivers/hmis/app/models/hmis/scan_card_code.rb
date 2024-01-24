###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ScanCardCode < Hmis::HmisBase
  self.table_name = 'hmis_scan_card_codes'
  acts_as_paranoid
  has_paper_trail

  belongs_to :client, optional: false, class_name: 'Hmis::Hud::Client'
  belongs_to :created_by, class_name: 'Hmis::User', optional: true
  belongs_to :deleted_by, class_name: 'Hmis::User', optional: true

  # Generate a code to use for a scan card.
  # Note that not all scan card code values will match this pattern, because some
  # scan cards might be migrated in from other systems.
  def self.generate_code
    'S' + SecureRandom.hex(5).upcase
  end

  # Assign a unique scan card code to this record
  def assign_code
    return if value.present?

    guard = 0
    while guard < 10
      code = self.class.generate_code
      break unless Hmis::ScanCardCode.with_deleted.where(value: code).exists?

      guard += 1
    end

    raise 'Failed to generate unique scan code' unless code

    self.value ||= code
  end
end
