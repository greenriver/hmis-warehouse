###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ApplicationHelper
  include Pagy::Frontend
  # permissions
  # See Role.rb for specifics of what permissions are available
  (Role.permissions + User.additional_permissions).each do |permission|
    define_method("#{permission}?") do
      current_user.try(permission)
    end
  end
  # END Permissions

  def yes_no(boolean, include_icon: true)
    case boolean
    when nil
      'Not Specified'
    when true, 'Yes'
      capture do
        concat content_tag :span, nil, class: 'icon-checkmark o-color--positive' if include_icon
        concat ' Yes'
      end
    when false, 'No'
      capture do
        concat content_tag :span, nil, class: 'icon-cross o-color--danger' if include_icon
        concat ' No'
      end
    when 'Refused'
      capture do
        concat content_tag :span, nil, class: 'icon-warning o-color--warning' if include_icon
        concat ' Refused/Unsure'
      end
    end
  end

  def yn(boolean)
    boolean ? 'Y' : 'N'
  end

  def checkmark(boolean, tooltip = nil, size: :xs, style: :font)
    return unless boolean

    checkmark_or_x(boolean, tooltip, size: size, style: style)
  end

  def checkmark_or_x(boolean, tooltip = nil, size: :xs, style: :font)
    if boolean
      symbol_name = 'checkmark'
      wrapper_class = 'o-color--positive'
    else
      symbol_name = 'cross'
      wrapper_class = 'o-color--danger'
    end
    html_class = "#{symbol_name} #{wrapper_class}"
    case size.to_sym
    when :md
      html_class += ' icon-lg'
    when :lg
      html_class += ' icon-xl'
    end
    case style
    when :svg
      svg_checkbox(wrapper_class: wrapper_class, symbol_name: symbol_name, size: size, tooltip: tooltip)
    else
      capture do
        concat content_tag :span, nil, { data: { toggle: :tooltip, title: tooltip }, class: "icon-#{html_class} inline-icon" }
      end
    end
  end

  def change_direction_icon direction, tooltip: ''
    allow_directions = [:up, :down, :none]
    direction = :none if allow_directions.exclude? direction.to_sym
    tooltip_data = {}
    tooltip_data = { toggle: :tooltip, title: tooltip } if tooltip.present?
    embedded_svg("change-#{direction}", options: tooltip_data)
  end

  def svg_checkbox(wrapper_class:, symbol_name:, size: 'xs', tooltip: nil)
    capture do
      content_tag(:span, class: "icon-svg--#{size} #{wrapper_class} mr-2", data: { toggle: :tooltip, title: tooltip }) do
        content_tag(:svg) do
          content_tag(:use, '', 'xlink:href' => "\#icon-#{symbol_name}")
        end
      end
    end
  end

  def ssn(number)
    if can_view_full_ssn?
      # pad with leading 0s if we don't have enough characters
      number = number.to_s.rjust(9, '0') if number.present?
      content_tag :span, number.to_s.gsub(/(\d{3})[^\d]?(\d{2})[^\d]?(\d{4})/, '\1-\2-\3')
    else
      masked_ssn(number)
    end
  end

  def masked_ssn(number)
    # pad with leading 0s if we don't have enough characters
    number = number.to_s.rjust(9, '0') if number.present?
    content_tag :span, number.to_s.gsub(/(\d{3})[^\d]?(\d{2})[^\d]?(\d{4})/, 'XXX-XX-\3')
  end

  def beautify_option(_key, value)
    return value unless value.is_a?(Array)

    clean = value.select(&:present?).map(&:to_i)
    return clean unless clean.count > 5

    "[#{clean[0...5].to_sentence(last_word_connector: ', ')}, ...]"
  end

  def dob_or_age(dob)
    if can_view_full_dob?
      dob
    else
      GrdaWarehouse::Hud::Client.age(date: Date.current, dob: dob)
    end
  end

  def date_format(dob)
    dob ? l(dob, format: :default) : ''
    # dob.try(:strftime, '%m/%d/%Y')
  end

  def dates_overlap(d_1_start, d_1_end, d_2_start, d_2_end)
    # Excellent discussion of why this works:
    # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overlap

    d_1_start < d_2_end && d_1_end > d_2_start
  rescue StandardError
    true
    # this catches empty
  end

  def quarter(date)
    month = date.month + 2
    (month.ceil / 3)
  end

  # returns the class associated with the current sort order of a column
  def current_sort_order(columns)
    columns[sort_column] = sort_direction
    columns
  end

  # returns a link appropriate for re-sorting a table
  def sort_link(link_text, column, directions, permitted_params = [])
    direction = directions[column]
    sort_direction = direction.nil? || direction == 'asc' ? 'desc' : 'asc'
    sort = { 'sort' => column, 'direction' => sort_direction }
    clean_params = params.permit(permitted_params + [:q])
    clean_params.merge!(sort)
    link_to(link_text, clean_params)
  end

  # returns a link appropriate for sorting a table as described
  def sort_as_link(link_text, column, direction = 'asc', permitted_params = [])
    sort_direction = direction.nil? || direction == 'asc' ? 'asc' : 'desc'
    sort = { 'sort' => column, 'direction' => sort_direction }
    clean_params = params.permit(permitted_params + [:q])
    clean_params.merge!(sort)
    link_to(link_text, clean_params)
  end

  def enable_responsive?
    @enable_responsive = true
  end

  def body_classes
    [].tap do |result|
      result << ENV.fetch('CLIENT')
      result << params[:controller]
      result << params[:action]
      result << 'not-signed-in' if current_user.blank?
      result << (@layout__width == 'lg' ? 'l-content-width-lg' : 'l-content-width-md')
    end
  end

  # because this comes up a fair bit...
  def hud_1_8(id)
    lighten_no HUD.list('1.8', id)
  end

  # make no less visually salient
  def lighten_no(value)
    if strip_tags(value&.to_s)&.strip&.downcase == 'no'
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

  def homeless_service_calendar(options = {}, &block)
    raise 'homeless_service_calendar requires a block' unless block_given?

    SimpleCalendar::HomelessService.new(self, options).render(&block)
  end

  # generates a list of HTML snippets representing the names the user is known by in different data sources
  def client_aliases(client)
    names = client.client_names(user: current_user, health: true)
    names.map do |name|
      sn = name[:ds]
      id = name[:ds_id]
      full_name = name[:name]
      if GrdaWarehouse::Config.get(:multi_coc_installation)
        content_tag(:div, full_name, class: 'mb-4')
      else
        content_tag(:em, sn, class: "ds-color-#{id}") + " #{full_name}"
      end
    end.uniq
  end

  def human_locale(locale)
    translations = {
      en: 'Text adjustments',
    }
    translations[locale.to_sym].presence || locale
  end

  def translated?(text)
    _(text) != text
  end

  def options_for_available_tags(grouped_tags, _selected_name)
    opts = []
    grouped_tags.each do |key, group|
      if group.size == 1
        item = group.first
        opts << content_tag(:option, item.name, value: item.name)
      else
        opts << content_tag(:optgroup, key, label: key)
        group.each do |group_item|
          opts << content_tag(:option, group_item.name, value: group_item.name)
        end
      end
    end
    opts.join('').html_safe
  end

  def branch_info
    branch_name = `git rev-parse --abbrev-ref HEAD`
    content_tag :div, class: 'navbar-text' do
      content_tag :span, branch_name, class: 'label label-warning'
    end
  end

  def impersonating?
    current_user != true_user
  end

  def modal_size
    ''
  end

  # http://cobwwweb.com/render-inline-svg-rails-middleman#sthash.0TA73Fi9.dpuf
  def svg(name)
    file_path = "#{Rails.root}/app/assets/images/#{name}.svg"
    return File.read(file_path).html_safe if File.exist?(file_path)

    '(not found)'
  end

  # embed an svg from a sprite (pick the symbol to use and give it a class)
  # should generate svg tag with classes passed surrounding a use tag with xlink:href att value of symbol_name
  def embedded_svg(symbol_name, *args)
    options = args.extract_options!
    style = "height: #{options[:height]}; width: #{options[:width]}" if options[:height]
    content_tag(
      :div,
      content_tag(
        :svg,
        content_tag(
          :use,
          '',
          'xlink:href' => "\#icon-#{symbol_name}",
          :class => options[:xlink_class],
        ),
        class: options[:class],
        style: style,
      ),
      class: "icon-svg #{options[:wrapper_class]}",
      style: style,
    )
  end

  def help_link
    @help_link ||= begin
      return nil unless help_for_path

      if help_for_path.external?
        link_to 'Help', help_for_path.external_url, class: 'o-menu__link', target: :_blank
      else
        link_to 'Help', help_path(help_for_path), class: 'o-menu__link', data: { loads_in_pjax_modal: true }
      end
    end
  end

  def help_for_path
    @help_for_path ||= GrdaWarehouse::Help.select(:id, :external_url, :location).for_path(
      controller_path: controller_path,
      action_name: action_name,
    )
  end

  # link_to_if doesn't print the block if the condition is true, this does
  def if_link_to(condition, name = nil, options = nil, html_options = nil, &block)
    if condition
      link_to(name, options, html_options, &block)
    else
      link_to_if(false, name, options, html_options, &block)
    end
  end

  def pill_badge(labels: [], wrapper_classes: ['badge-dark'])
    tag.div class: ['badge-pill'] + wrapper_classes do
      tag.dl class: 'badge-pill__content' do
        concat(
          tag.dt(labels.first) +
          tag.dd(labels.last),
        )
      end
    end
  end

  def percentage(value, format: '%1.2f')
    value = 0 if value.to_f&.nan?

    format(format, value.round(2))
  end

  def report_filter_visible?(key, user)
    user.report_filter_visible?(key)
  end
end
