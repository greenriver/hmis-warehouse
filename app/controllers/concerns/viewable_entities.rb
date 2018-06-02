module ViewableEntities
  extend ActiveSupport::Concern
  included do
    # some helpers factored out of a view for the sake of readability

    private def data_source_viewability(base)
      {
        selected:    @user.data_sources.map(&:id),
        input_html:  { class: 'jUserViewable', name: "#{base}[data_sources][]" },
        collection:  GrdaWarehouse::DataSource.viewable_by(current_user).order(:name),
        placeholder: 'Data Source',
        multiple:    true
      }
    end
    helper_method :data_source_viewability

    private def organization_viewability(base)
      model = GrdaWarehouse::Hud::Organization.viewable_by(current_user)
      collection = model
        .order(:name)
        .preload(:data_source)
        .group_by{ |o| o.data_source.name }
      {
        as:           :grouped_select,
        group_method: :last,
        selected:     @user.organizations.map(&:id),
        collection:   collection,
        placeholder:  'Organization',
        multiple:     true,
        input_html: {
          class: 'jUserViewable',
          name:  "#{base}[organizations][]"
        },
      }
    end
    helper_method :organization_viewability

    private def project_viewability(base)
      model = GrdaWarehouse::Hud::Project.viewable_by(current_user)
      collection = model
        .order(:name)
        .preload( :organization, :data_source )
        .group_by{ |p| "#{p.data_source&.name} / #{p.organization&.name}" }
      {
        as:           :grouped_select,
        group_method: :last,
        selected:     @user.projects.map(&:id),
        collection:   collection,
        placeholder:  'Project',
        multiple:     true,
        input_html: {
          class: 'jUserViewable',
          name:  "#{base}[projects][]"
        },
      }
    end
    helper_method :project_viewability

    private def coc_viewability(base)
      collection = %w[ ProjectCoc EnrollmentCoc ].flat_map do |c|
        "GrdaWarehouse::Hud::#{c}".constantize.distinct.pluck :CoCCode
      end.uniq&.compact&.sort
      {
        label:       'CoC codes',
        selected:    @user.coc_codes,
        collection:  collection,
        placeholder: 'Project',
        multiple:    true,
        input_html: {
          class: 'jUserViewable',
          name:  "#{base}[coc_codes][]"
        },
      }
    end
    helper_method :coc_viewability

    private def reports_viewability(base)
      model = GrdaWarehouse::WarehouseReports::ReportDefinition.viewable_by(current_user)
      collection = model.order( :report_group, :name ).map do |rd|
        [ "#{rd.report_group}: #{rd.name}", rd.id ]
      end
      {
        selected:    @user.reports.map(&:id),
        collection:  collection,
        placeholder: 'Report',
        multiple:    true,
        input_html: {
          class: 'jUserViewable',
          name:  "#{base}[reports][]"
        },
      }
    end
    helper_method :reports_viewability

    private def cohort_viewability(base)
      model = GrdaWarehouse::Cohort.viewable_by(current_user)
      {
        selected:    @user.cohorts.map(&:id),
        collection:  model.order(:name),
        placeholder: 'Cohort',
        multiple:    true,
        input_html: {
          class: 'jUserViewable',
          name:  "#{base}[cohorts][]"
        },
      }
    end
    helper_method :cohort_viewability
  end
end