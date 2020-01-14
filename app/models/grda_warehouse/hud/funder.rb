###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class Funder < Base
    include HudSharedScopes
    self.table_name = 'Funder'
    self.hud_key = :FunderID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      case version
      when '5.1', '6.11', '6.12'
        [
          :FunderID,
          :ProjectID,
          :Funder,
          :GrantID,
          :StartDate,
          :EndDate,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      when '2020'
        [
          :FunderID,
          :ProjectID,
          :Funder,
          :OtherFunder,
          :GrantID,
          :StartDate,
          :EndDate,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      else
        [
          :FunderID,
          :ProjectID,
          :Funder,
          :GrantID,
          :StartDate,
          :EndDate,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      end
    end

    belongs_to :project, **hud_assoc(:ProjectID, 'Project'), inverse_of: :funders
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :funders, optional: :true
    belongs_to :data_source

    scope :open_between, -> (start_date:, end_date: ) do
      at = arel_table

      closed_within_range = at[:StartDate].gt(start_date).
        and(at[:StartDate].lteq(end_date))
      opened_within_range = at[:StartDate].gteq(start_date).
        and(at[:StartDate].lt(end_date))
      open_throughout = at[:StartDate].lt(start_date).
        and(at[:EndDate].gt(start_date).
          or(at[:EndDate].eq(nil))
        )
      where(closed_within_range.or(opened_within_range).or(open_throughout))
    end

    def valid_funder_code?
      self.class.valid_funder_code?(self.Funder)
    end

    def self.valid_funder_code? funder
      HUD.funding_sources.keys.include?(funder)
    end

    def operating_year
      "#{self.StartDate} - #{self.EndDate}"
    end

    def self.related_item_keys
      [:ProjectID]
    end
  end
end