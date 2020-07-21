#= require ./namespace

class App.Reports.CocOverlap
  constructor: (@elementId, @props={}) ->
    @MAX_SELECTIONS = 2
    @state = {
      selections: [],
      selectionIndex: 0,
    }
    # Init map
    # give DOM id/shape data and update form callback for when
    # shape is clicked
    @map = new App.Maps.MapWithShapes @props.map, @updateForm
    @props.inputs.forEach (input, i) =>
      $(input).on 'select2:select', @handleSelectionChange.bind(@)
    @props.dateInputs.forEach (input, i) =>
      $(input).on 'change', @report.bind(@)


  handleSelectionChange: (event, value) =>
    { selections } = @state
    # Get the selection index — if from input, base it off of the
    # inputs indext if not, use the current index
    index = if event.target? then @props.inputs.indexOf("##{event.target.id}")
    # Update the map shapes to reflext changes in selection state
    @map.updateSelections(event.target?.value || value, index)
    selections[@state.selectionIndex] = +value || +event.target?.value
    @updateSelectedIndex()
    @report()

  updateForm: (record_id) =>
    { inputs } = @props
    { selections } = @state
    currentIndex = @state.selectionIndex

    # Update selections in state to selected
    selections[currentIndex] = +record_id

    # Update Form inputs
    selections.forEach (s, i) =>
      $(inputs[i]).val(s).trigger 'change'
    @updateSelectedIndex()
    # return the current index for when it's called from
    # the map class as a click callback
    @report()
    currentIndex

  # Manage the index of the current selection
  updateSelectedIndex: =>
    if @state.selectionIndex >= @MAX_SELECTIONS-1
      @state.selectionIndex = 0
    else
      @state.selectionIndex++

  loading: (loading) =>
    opacity = 1
    pointerEvents = 'all'
    if loading
      opacity = .4
      pointerEvents = 'none'
    containers = ['results', 'map']
    loaderClass = 'j-loading-indecator'
    containers.forEach (container) =>
      $container = $("##{@elementId}-#{container}").css({opacity, pointerEvents})
      if loading
        $container.prepend(
          """
            <div class='#{loaderClass}'>
              <div class="c-loading c-loading--lg c-loading--dark c-loading--center">
                <div class="c-loading__dot"></div>
                <div class="c-loading__dot"></div>
                <div class="c-loading__dot"></div>
                <div class="c-loading__dot"></div>
                <div class="c-loading__dot"></div>
                <div class="c-loading__dot"></div>
              </div>
            <div>
          """
        )
      else
        $container.find(".#{loaderClass}").remove()

  report: =>
    if @state.selections.length > 0
      @loading(true)
      $.ajax(
        type: 'GET'
        url: '/warehouse_reports/overlapping_coc_utilization/overlap'
        data: $("##{@elementId} form").serialize()
      ).done(
        @updateResults.bind(@)
      ).fail (xhr) =>
        @loading(false)
        alert(xhr.responseText)

  updateResults: (data) =>
    $("##{@elementId}-results").html data.html
    @map.updateData(data.map, @state.selections)
    @loading(false)
