module ApplicationHelper
  # permissions
  # See Role.rb for specifics of what permissions are available
  Role.permissions.each do |permission|
    define_method("#{permission}?") do
      current_user.try(permission)
    end
  end
  # END Permissions

  def yes_no boolean
    case boolean
    when nil
      "Not Specified"
    when true, "Yes"
      capture do
        concat content_tag :span, nil, class: 'icon-checkmark', style: 'color:green'
        concat " Yes"
      end
    when false, "No"
      capture do
        concat content_tag :span, nil, class: 'icon-cross', style: 'color:red'
        concat " No"
      end
    when "Refused"
      capture do
        concat content_tag :span, nil, class: 'icon-warning', style: 'color:#8a6d3b'
        concat " Refused/Unsure"
      end
    end
  end

  def yn(boolean)
    boolean ? 'Y': 'N'
  end

  def checkmark(boolean)
    boolean ? '✓': ''
  end

  def ssn(number)
    # pad with leading 0s if we don't have enough characters
    number = number.to_s.rjust(9, '0') if number.present?
    content_tag :span, number.to_s.gsub(/(\d{3})[^\d]?(\d{2})[^\d]?(\d{4})/, '\1-\2-\3')
  end

  def masked_ssn(number)
    # pad with leading 0s if we don't have enough characters
    number = number.to_s.rjust(9, '0') if number.present?
    content_tag :span, number.to_s.gsub(/(\d{3})[^\d]?(\d{2})[^\d]?(\d{4})/, 'XXX-XX-\3')
  end

  def date_format(dob)
    dob ? l(dob, format: :default) : ''
    #dob.try(:strftime, '%m/%d/%Y')
  end

  def dates_overlap d_1_start, d_1_end, d_2_start, d_2_end
    # Excellent discussion of why this works:
    # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overlap
    d_1_start < d_2_end && d_1_end > d_2_start rescue true # this catches empty
  end 

  # returns the class associated with the current sort order of a column
  def current_sort_order(columns)
    columns[sort_column] = sort_direction
    return columns
  end

  # returns a link appropriate for re-sorting a table
  def sort_link(link_text, column, directions)
    direction = directions[column]
    sort_direction = (direction.nil? || direction == 'asc') ? 'desc' : 'asc'
    sort = {'sort' => column, 'direction' => sort_direction}
    params.merge!(sort)
    link_to(link_text, params)
  end

  #returns a link appropriate for sorting a table as described
  def sort_as_link(link_text, column, direction='asc')
    sort_direction = (direction.nil? || direction == 'asc') ? 'asc' : 'desc'
    sort = {'sort' => column, 'direction' => sort_direction}
    params.merge!(sort)
    link_to(link_text, params)
  end

  def enable_responsive?
    @enable_responsive  = true
  end

  def body_classes
    [].tap do |result|
      result << params[:controller]
      result << params[:action]
    end
  end

  # because this comes up a fair bit...
  def hud_1_8(id)
    lighten_no HUD::list( '1.8', id )
  end

  # make no less visually salient
  def lighten_no(value)
    if value == 'No'
      content_tag :i, value, class: :light
    else
      value
    end
  end

  def container_classes
    [].tap do |result|
      result << 'non-responsive' unless enable_responsive?
    end
  end

  def homeless_service_calendar(options={}, &block)
    raise 'homeless_service_calendar requires a block' unless block_given?
    SimpleCalendar::HomelessService.new(self, options).render(&block)
  end

  # generates a list of HTML snippets representing the names the user is known by in different data sources
  def client_aliases(client)
    if controller_path.include?('window')
      client_scope = client.source_clients.visible_in_window
    else
      client_scope = client.source_clients
    end
    client_scope.
      where.not(FirstName: client.FirstName, LastName: client.LastName, MiddleName: client.MiddleName).
      map do |n|
      sn = n.data_source.short_name
      content_tag( :em, sn, class: "ds-#{sn.downcase}" ) + " #{n.full_name}"
    end

  end

  def human_locale(locale)
    translations = {
      en: 'Text adjustments'
    }
    translations[locale.to_sym].presence || locale
  end

end
