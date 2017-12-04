$ ->

  $(document).on 'change', '.submit-on-change', (e) ->
    form = $(e.target).closest 'form'
    form.submit()