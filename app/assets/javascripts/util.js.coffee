# a collection of utility functions in the App.util namespace

util = window.App.util ?= {}

# pick a color within a range with endpoints hue1 and hue2 (hue-saturation-lumosity color)
util.fractionToColor = (fraction, hue0, hue1, saturation, lumosity) ->
  hue = Math.round( ( fraction * ( hue1 - hue0 ) ) + hue0 )
  "hsl(#{hue}, #{saturation}%, #{lumosity}%)"

util.rangeToColor = ( point, low, high, bottom, top, saturation, lumosity ) ->
  throw "point(#{point}), low(#{point}), and high(#{high}) must all be defined" unless point? and low? and high?
  throw "it must be that low <= point <= high (point: #{point}" unless low <= point <= high
  fraction = ( point - low ) / ( high - low )
  util.fractionToColor fraction, bottom, top, saturation, lumosity

# this produces a color dot you can place on the page
util.colorDot = (obj) ->
  obj.shape = 'circle'
  util.colorShape obj

util.colorSquare = (obj) ->
  obj.shape = 'square'
  util.colorShape obj

# make a list of colors along a gradient
util.colorList = ({
  n          # a number of colors
  interleave # whether to interleave colors from different parts of the gradient for better contrast
  saturation # see colorShape
  lumosity   #  "
  colorLow   #  "
  colorHigh  #  "
}) ->
  saturation ?= 100
  lumosity   ?= 35
  colorLow   ?= 120
  colorHigh  ?= 0

  list = ( util.rangeToColor i, 0, n, colorLow, colorHigh, saturation, lumosity for i in [0...n] )
  if interleave
    mid = Math.ceil n / 2
    newList = []
    for i in [0...mid]
      newList.push list[i]
      j = i + mid
      newList.push list[j] if j < n
    list = newList
  return list

util.colorShape = ({
  point      # a point in some range of values
  low        # the low end of the range
  high       # the high end of the range
  radius     # half the larges dimension of the shape
  center     # whether to try to make the thing self-centering
  saturation # the degree of color saturation -- a percentage, so in the range 0-100
  lumosity   # brightness, also a percentage
  colorHigh  # the "color", represented as a degree rotation around the color circle, corresonding to the high end of the range
  colorLow   # same for low end
  shape      # the shape to draw
}) ->
  radius     ?= 5
  center     ?= false  # just to be explicit
  saturation ?= 100
  lumosity   ?= 35
  colorLow   ?= 120
  colorHigh  ?= 0

  color = util.rangeToColor point, low, high, colorLow, colorHigh, saturation, lumosity
  dim   = radius * 2
  css =
    display:         'inline-block'
    minHeight:          "#{dim}px"
    minWidth:           "#{dim}px"
    backgroundColor: color
  switch shape
    when 'square' then # all is well
    when 'circle'
      css.borderRadius = "#{radius}px"
    else
      # all is well
  css.margin = "auto auto" if center
  $('<div/>').css css

# takes a jquerified element and selects its contents
util.select = ($e) ->
  if document.body.createTextRange
    range = document.body.createTextRange()
    range.moveToElementText($e[0])
    range.select()
  else if window.getSelection
    selection = window.getSelection()
    range = document.createRange()
    range.selectNodeContents($e[0])
    selection.removeAllRanges()
    selection.addRange(range)

# selects the text in a particular jquerified element and attempts to copy it to the clipboard
# if you pass this a jQuery object, it copies the text of the selected element
# otherwise, it creates a temporary element, copies the text out of that, and deletes the element
util.copyToClipboard = ($e) ->
  unless typeof $e is 'object'
    t = $e
    $e = $ '<span/>'
    $e.text t
    $('body').append $e
    deleteMe = true
  if $e.length
    util.select $e
    try
      document.execCommand 'copy'
    catch
      console.log 'could not copy tooltip text'
  $e.remove() if deleteMe

util.hashCode = (str) ->
  hash = 0
  if str.length == 0
    return hash
  else
    for i in [0..str.length - 1] by 1
      char = str.charCodeAt(i)
      hash = ((hash<<5)-hash)+char
      hash = hash & hash # Convert to 32bit integer
    return hash

util.intToRGB = (i) ->
  c = (i & 0x00FFFFFF).toString(16).toUpperCase()
  "00000".substring(0, 6 - c.length) + c
