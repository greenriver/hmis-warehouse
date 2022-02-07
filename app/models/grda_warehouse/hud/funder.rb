###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Funder < Base
    include HudSharedScopes
    include ::HMIS::Structure::Funder
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'Funder'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :project, **hud_assoc(:ProjectID, 'Project'), inverse_of: :funders, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :funders, optional: true
    belongs_to :data_source

    scope :importable, -> do
      where(manual_entry: false)
    end

    scope :open_between, ->(start_date:, end_date:) do
      at = arel_table

      closed_within_range = at[:StartDate].gt(start_date).
        and(at[:StartDate].lteq(end_date))
      opened_within_range = at[:StartDate].gteq(start_date).
        and(at[:StartDate].lt(end_date))
      open_throughout = at[:StartDate].lt(start_date).
        and(at[:EndDate].gt(start_date).
          or(at[:EndDate].eq(nil)))
      where(closed_within_range.or(opened_within_range).or(open_throughout))
    end

    scope :within_range, ->(range) do
      where(
        f_t[:EndDate].gteq(range.first).
        or(f_t[:EndDate].eq(nil)).
        and(f_t[:StartDate].lteq(range.last).
          or(f_t[:StartDate].eq(nil))),
      )
    end

    scope :funding_source, ->(funder_code: nil, other: nil) do
      if other.present?
        where(Funder: funder_code, OtherFunder: other)
      else
        where(Funder: funder_code)
      end
    end

    scope :viewable_by, ->(user) do
      joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(user))
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

    def self.options_for_select(user:)
      viewable_by(user).
        distinct.
        order(Funder: :asc).
        pluck(:Funder).
        map do |funder_code|
          [
            "#{HUD.funding_source(funder_code&.to_i)} (#{funder_code})",
            funder_code,
          ]
        end
    end

    def self.related_item_keys
      [:ProjectID]
    end

    # when we export, we always need to replace FunderID with the value of id
    def self.to_csv(scope:)
      attributes = hud_csv_headers.dup
      headers = attributes.clone
      attributes[attributes.index(:FunderID)] = :id
      attributes[attributes.index(:ProjectID)] = 'project.id'

      CSV.generate(headers: true) do |csv|
        csv << headers

        scope.each do |i|
          csv << attributes.map do |attr|
            attr = attr.to_s
            v = if attr.include?('.')
              obj, meth = attr.split('.')
              i.send(obj).send(meth)
            elsif attr == 'GrantID' && i.GrantID.blank?
              'Unknown'
            elsif attr == 'OtherFunder' && i.OtherFunder.present?
              i.OtherFunder[0...50]
            else
              i.send(attr)
            end
            if v.is_a? Date
              v = v.strftime('%Y-%m-%d')
            elsif v.is_a? Time
              v = v.to_formatted_s(:db)
            end
            v
          end
        end
      end
    end
  end
end
