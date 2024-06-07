###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Base < ::GrdaWarehouseBase
  self.abstract_class = true
  include ::Hmis::Concerns::HmisArelHelper

  acts_as_paranoid(column: :DateDeleted)

  attr_writer :skip_validations
  attr_writer :required_fields

  def self.without_optimistic_locking
    prev = lock_optimistically
    self.lock_optimistically = false
    begin
      yield
    ensure
      self.lock_optimistically = prev
    end
  end

  before_validation :ensure_id

  scope :viewable_by, ->(_) do
    none
  end

  def self.hmis_relation(col, model_name = nil)
    h = {
      primary_key: [
        :data_source_id,
        col,
      ],
      foreign_key: [
        :data_source_id,
        col,
      ],
      autosave: false,
    }
    h.merge! class_name: "Hmis::Hud::#{model_name}" if model_name
    h
  end

  def self.hmis_enrollment_relation(model_name = nil)
    model_name = if model_name.present?
      "Hmis::Hud::#{model_name}"
    else
      'Hmis::Hud::Enrollment'
    end
    h = {
      primary_key: [
        :EnrollmentID,
        :PersonalID,
        :data_source_id,
      ],
      foreign_key: [
        :EnrollmentID,
        :PersonalID,
        :data_source_id,
      ],
      class_name: model_name,
      autosave: false,
    }
    h
  end

  def self.alias_to_underscore(cols)
    Array.wrap(cols).each do |col|
      alias_attribute col.to_s.underscore.to_sym, col
    end
  end

  # Create aliases for common HUD fields
  alias_to_underscore [:UserID, :DateCreated, :DateUpdated, :DateDeleted]

  def self.generate_uuid
    SecureRandom.uuid.gsub(/-/, '')
  end

  # Fields that should be skipped during validation.
  def skip_validations
    @skip_validations ||= []
  end

  # Fields that should be validated as required during validation.
  # NOTE: No need to add fields here if they are not already required by the warehouse validator.
  def required_fields
    @required_fields ||= []
  end

  private def ensure_id
    return unless self.class.respond_to?(:hud_key)
    return if send(self.class.hud_key).present? # Don't overwrite the ID if we already have one

    assign_attributes(self.class.hud_key => self.class.generate_uuid)
  end

  # Let Rails update the HUD timestamps
  def self.timestamp_attributes_for_create
    super << 'DateCreated'
  end

  def self.timestamp_attributes_for_update
    super << 'DateUpdated'
  end

  MAX_PK = 2_147_483_648 # PK is a 4 byte signed INT (2 ** ((4 * 8) - 1))

  # Determine whether the given search term is possibly a Primary Key (it's numeric and less than 4 bytes)
  def self.possibly_pk?(search_term) # could add optional arg for 4 byte vs 8 byte, if needed later
    search_term =~ /\A\d+\z/ && search_term.to_i < MAX_PK
  end
end
