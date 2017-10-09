#= require ./namespace

class App.Cohorts.Client
  constructor: (@row_selector, @input_selector, @check_url) ->
    @refresh_rate = 2500
    @init()

  init: =>
    $('body').on 'change', @input_selector, (e) ->
      $(@).closest('form').trigger('submit')

    $('body').on 'focus', @input_selector, (e) =>
      $input = $(e.currentTarget).find('select,input')
      cohort_client_id = $(e.currentTarget).closest(@row_selector).data('cohort-client-id')
      form = $input.closest('form')
      current_state = @update_state(form.attr('action'), cohort_client_id)

    setInterval @check_for_new_data, @refresh_rate

  check_for_new_data: =>
    existing = {} 
    $(@row_selector).each () ->
      existing[$(@).data('cohort-client-id')] = $(@).data('cohort-client-updated-at')
    $.get @check_url, (data) =>
      if data != existing
        @update_outdated(data, existing)

  update_outdated: (current, existing) =>
    for cohort_client_id, updated_at of existing
      if current[cohort_client_id] != updated_at
        url = "#{@check_url}/#{cohort_client_id}"
        @update_state(url, cohort_client_id)

  update_state: (url, cohort_client_id) =>
    $.get url, (data) =>
      row = $("#{@row_selector}[data-cohort-client-id='#{cohort_client_id}']")
      for k,v of data
        existing = $(row).find("[name='cohort_client[#{k}]']")
        if existing?
          existing.val(v) if existing.val() != v
      
      $(row).data('cohort-client-updated-at', data.updated_at_i)
