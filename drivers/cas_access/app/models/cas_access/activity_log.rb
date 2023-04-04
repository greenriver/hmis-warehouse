###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class ActivityLog < CasBase
    self.table_name = :activity_logs
    belongs_to :user

    def self.to_a(user_id: nil, range: 1.years.ago..Time.current)
      return nil unless db_exists?

      columns = {
        user_id: 'CAS User ID',
        agency_name_column => 'Agency Name',
        path: 'Path',
        created_at: 'Access Time',
        session_hash: 'Session',
        ip_address: 'IP Address',
        referrer: 'Referrer',
      }
      scope = where(created_at: range).left_outer_joins(user: :agency)
      scope = scope.where(user_id: user_id) if user_id.present?
      data = pluck_to_hash(columns, scope)
      data = scrub(data)

      rows = []
      rows << columns.values
      data.each do |row|
        rows << row.values_at(*columns.keys)
      end

      rows
    end

    def self.agency_name_column
      CasAccess::Agency.arel_table[:name]
    end

    def self.scrub(data)
      data.map do |row|
        # Strip anything after the ?
        row[:path]&.gsub!(/\?.*/, '')
        row[:referrer]&.gsub!(/\?.*/, '')
        row[:created_at] = row[:created_at].to_s(:db)
        row
      end
    end

    def self.pluck_to_hash(columns, scope, exclude: [])
      keys = columns.keys.excluding(exclude)
      scope.pluck(*keys).map do |row|
        Hash[keys.zip(row)]
      end
    end
  end
end
