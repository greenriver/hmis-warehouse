#= require ./namespace

class App.Reports.CocOverlap
  constructor: (@elementId, @props={}) ->
    @MAX_SELECTIONS = 2
    @state = {
      selections: [],
      selectionIndex: 0,
      loading: false,
    }
    @map = new App.Maps.MapWithShapes @props.map, @updateForm
    @props.inputs.forEach (input, i) =>
      $(input).on 'select2:select', @handleSelectionChange.bind(@)


  handleSelectionChange: (event, value) =>
    index = @state.selectionIndex
    index = if event.target? then @props.inputs.indexOf("##{event.target.id}")
    @map.update(event.target?.value || value, index)
    @updateSelectedIndex()


  updateForm: (record_id) =>
    { inputs } = @props
    { selections } = @state
    arrayMethod = 'push'
    currentIndex = @state.selectionIndex
    selections[currentIndex] = record_id

    # Update Form inputs
    selections.forEach (s, i) =>
      $(inputs[i]).val(s).trigger 'change'
    @updateSelectedIndex()
    currentIndex

  # Manage the index of the current selection
  updateSelectedIndex: =>
    if @state.selectionIndex >= @MAX_SELECTIONS-1
      @state.selectionIndex = 0
    else
      @state.selectionIndex++
