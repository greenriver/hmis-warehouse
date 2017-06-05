module GrdaWarehouse::Hud
  class Funder < Base
    self.table_name = 'Funder'
    self.hud_key = 'FunderID'
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        "FunderID",
        "ProjectID",
        "Funder",
        "GrantID",
        "StartDate",
        "EndDate",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ]
    end

    belongs_to :project, **hud_belongs(Project), inverse_of: :funders
    belongs_to :export, **hud_belongs(Export), inverse_of: :funders

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

    def operating_year
      "#{self.StartDate} - #{self.EndDate}"
    end
  end
end