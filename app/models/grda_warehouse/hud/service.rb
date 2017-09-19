module GrdaWarehouse::Hud
  class Service < Base
    self.table_name = 'Services'
    self.hud_key = 'ServicesID'
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        "ServicesID",
        "ProjectEntryID",
        "PersonalID",
        "DateProvided",
        "RecordType",
        "TypeProvided",
        "OtherTypeProvided",
        "SubTypeProvided",
        "FAAmount",
        "ReferralOutcome",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ]
    end

    belongs_to :data_source, inverse_of: :services
    belongs_to :direct_client, **hud_belongs(Client), inverse_of: :direct_services
    has_one :client, through: :enrollment, inverse_of: :services
    belongs_to :enrollment, class_name: GrdaWarehouse::Hud::Enrollment.name, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id], inverse_of: :services
    belongs_to :export, **hud_belongs(Export), inverse_of: :services
    has_one :project, through: :enrollment
    has_one :organization, through: :project

    scope :bed_night, -> { where RecordType: 200 }
    scope :descending, -> { order arel_table[:DateProvided].desc }
    # really, the scope below should just be true, but it isn't; this culls things down to the most recent entry of the given type for the date
    scope :uniqueness_constraint, -> {
      st1 = arel_table
      st2 = Arel::Table.new st1.table_name
      st2.table_alias = 'st2'
      where(
        st2.project(Arel.star).
          where( st2[:data_source_id].eq st1[:data_source_id] ).
          where( st2[:PersonalID].eq st1[:PersonalID] ).
          where( st2[:RecordType].eq st1[:RecordType] ).
          where( st2[:ProjectEntryID].eq st1[:ProjectEntryID] ).
          where( st2[:DateProvided].eq st1[:DateProvided] ).
          where( st2[:id].gt st1[:id] ).
          exists.not
      )
    }
  end
end