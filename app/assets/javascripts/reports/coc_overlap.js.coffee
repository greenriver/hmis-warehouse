#= require ./namespace

class App.Reports.CocOverlap
  constructor: (@elementId, @props={}) ->
    @MAX_SELECTIONS = 2
    @state = {
      selections: [],
      selectionIndex: 0,
      loading: false,
    }
    # Init map
    # give DOM id/shape data and update form callback for when
    # shape is clicked
    @map = new App.Maps.MapWithShapes @props.map, @updateForm
    @props.inputs.forEach (input, i) =>
      $(input).on 'select2:select', @handleSelectionChange.bind(@)


  handleSelectionChange: (event, value) =>
    # Get the selection index — if from input, base it off of the
    # inputs indext if not, use the current index
    index = @state.selectionIndex
    index = if event.target? then @props.inputs.indexOf("##{event.target.id}")
    # Update the map shapes to reflext changes in selection state
    @map.update(event.target?.value || value, index)
    @updateSelectedIndex()


  updateForm: (record_id) =>
    { inputs } = @props
    { selections } = @state
    currentIndex = @state.selectionIndex

    # Update selections in state to selected
    selections[currentIndex] = record_id

    # Update Form inputs
    selections.forEach (s, i) =>
      $(inputs[i]).val(s).trigger 'change'
    @updateSelectedIndex()
    # return the current index for when it's called from
    # the map class as a click callback
    currentIndex

  # Manage the index of the current selection
  updateSelectedIndex: =>
    if @state.selectionIndex >= @MAX_SELECTIONS-1
      @state.selectionIndex = 0
    else
      @state.selectionIndex++
