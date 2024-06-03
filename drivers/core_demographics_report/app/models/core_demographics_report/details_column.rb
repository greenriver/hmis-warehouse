# CoreDemographicsReport::DetailsColumn
module CoreDemographicsReport
  DetailsColumn = Struct.new(:label, :index, :user, :project_id_index, keyword_init: true) do
    def value(row)
      raw_value = row[index]

      project_id = row[project_id_index]
      policy = user.policies.for_project(project_id)
      pii_value(raw_value, policy)
    end

    protected

    def pii_value(raw_value, policy)
      case label
      when 'First Name', 'Last Name'
        GrdaWarehouse::PiiProvider.viewable_name(raw_value, policy: policy)
      when 'DOB'
        GrdaWarehouse::PiiProvider.viewable_dob(raw_value, policy: policy)
      else
        raw_value
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
