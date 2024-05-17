
# CoreDemographicsReport::DetailsColumn
module CoreDemographicsReport
  DetailsColumn = Struct.new(:label, :index, :pii, :user, :project_id_index, keyword_init: true) do
    def value(row)
      raw_value = row[index]
      return raw_value unless pii

      project_id = row[project_id_index]
      policy = user.policies.for_project(project_id)
      return pii_value(raw_value, policy)
    end

    protected

    REDACTED = 'Redacted'
    def pii_value(raw_value, policy)
      case label
      when 'First Name', 'Last Name'
        policy.can_view_client_name? ? raw_value : REDACTED
      when 'DOB'
        policy.can_view_full_dob? ? raw_value : REDACTED
      end
    end

    def field
      @field ||= label.gsub(' ', '_').downcase
    end
  end

  def column_objects_for(key)
    raw = detail_hash.dig(key, :headers) || []
    project_id_index = raw.index('_project_id')
    raw.map.with_index do |label, index|
      next if index == project_id_index # we don't show project id, it's just for permissions
      CoreDemographicReportColumn.new(
        label: label,
        index: index,
        pii: label.in?(pii_headers),
        user: filter.user,
        project_id_index: project_id_index,
      )
    end.compact
  end
end
