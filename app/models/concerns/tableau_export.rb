###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TableauExport
  extend ActiveSupport::Concern
  included do
    module_function

    def default_start
      '2014-01-01'.to_date
    end
    private_class_method :default_start

    def default_end
      DateTime.current
    end
    private_class_method :default_end

    def project_types
      [
        1, # => 'Emergency Shelter',
        2, #=> 'Transitional Housing',
        3, #=> 'PH – Permanent Supportive Housing',
        4, #=> 'Street Outreach',
        6, #=> 'Services Only',
        7, #=> 'Other',
        8, #=> 'Safe Haven',
        9, #=> 'PH – Housing Only',
        10, #=> 'PH – Housing with Services (no disability required for entry)',
        11, #=> 'Day Shelter',
        12, #=> 'Homelessness Prevention',
        13, #=> 'PH - Rapid Re-Housing',
        14, #=> 'Coordinated Assessment',
      ]
    end

    def null
      lit 'NULL'
    end
    private_class_method :null

    def pathways_common(start_date: default_start, end_date: default_end, coc_code: nil)
      model = GrdaWarehouse::ServiceHistoryEnrollment
      spec = {
        client_uid: she_t[:client_id], # in use
        hh_config: she_t[:presented_as_individual],
        prog: she_t[model.project_type_column], # in use
        entry: she_t[:first_date_in_program], # in use
        exit: she_t[:last_date_in_program], # in use
        destination: she_t[:destination], # in use
        coc_code: ec_t[:CoCCode], # in use
        coc_name: nil, # in use
      }
      repeaters = [:prog, :entry, :exit, :destination, :coc_code, :coc_name]
      non_repeaters = spec.keys - repeaters

      scope = model.
        joins(:client, enrollment: :enrollment_cocs).
        # merge( model.hud_residential ). # maybe spurious?
        merge(
          model.in_project_type(project_types).
            open_between(start_date: start_date, end_date: end_date).
            with_service_between(start_date: start_date, end_date: end_date),
        ).
        where(ec_t[:DataCollectionStage].eq 1).
        order(she_t[:client_id].asc).
        order(she_t[:first_date_in_program].asc).
        order(she_t[:last_date_in_program].asc)

      scope = scope.where(ec_t[:CoCCode].eq coc_code) if coc_code.present?
      paths = scope
      spec.each do |header, selector|
        next if selector.nil?

        paths = paths.select selector.as(header.to_s)
      end

      # each row may represent multiple enrollments
      # each enrollment is represented by a set of the repeater headers suffixed with a one-based index
      # we collect the rows and then pad them with nils, as needed so they are all the same width
      paths = model.connection.select_all(paths.to_sql)

      paths = paths.group_by { |h| h['client_uid'] }
      rows = []
      headers = Set[*non_repeaters]

      paths.each do |_, inner_paths|
        path = inner_paths.last # get the common data from the most recent enrollment
        row = []
        non_repeaters.map do |h|
          value = path[h.to_s].presence
          value = case h

          when :hh_config
            value == 't' ? 'Single' : 'Family'
          else
            value
          end
          row << value
        end

        inner_paths.first(3).each_with_index do |inner_path, i|
          repeaters.each do |h|
            headers << "#{h}#{i + 1}".to_sym
            value = inner_path[h.to_s].presence
            value = case h
            # when :prog
            #   ::HUD.project_type value.to_i if value
            when :entry, :exit
              value && DateTime.parse(value).strftime('%Y-%m-%d')
            # when :destination
            #   ::HUD.destination value.to_i if value
            when :coc_name
              ::HUD.coc_name(inner_path['coc_code'])
            else
              value
            end
            row << value
          end
        end

        rows << row
      end
      # pad the rows
      rows.each do |row|
        row.concat Array.new headers.length - row.length, nil
      end

      rows.unshift headers.to_a
      rows
    end
    private_class_method :pathways_common
  end
end
