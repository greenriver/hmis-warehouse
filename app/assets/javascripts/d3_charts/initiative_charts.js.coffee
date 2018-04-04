#= require ./namespace
#= require ./responsive_base

class App.D3Chart.ColorCodedTable
  constructor: (table_selector, keys, scale, selector='[data-d3-key]') ->
    @table = d3.select(table_selector)
    @selector = selector
    @keys = keys
    @scale = scale

  drawTableColors: () ->
    that = @
    @table.selectAll(@selector).each(() ->
      ele = d3.select(this)
      d = ele.node().getAttribute('data-d3-key')
      ele.append('span')
        .attr('style', 'background-color: '+that.scale(that.keys.indexOf(d)))
    )

class App.D3Chart.InitiativeToolTip

  constructor: (selector) ->
    @selector = selector
    @tooltip = d3.select(selector)

  element: () ->
    @tooltip

  show: (d) ->
    event = d3.event
    @tooltip
      .style('left', event.pageX+'px')
      .style('top', event.pageY+'px')
      .style('display', 'block')

    @tooltip.transition()
      .duration(50)
      .style('opacity', 1)

  hide: (d) ->
    @tooltip.transition()
      .duration(500)
      .style('opacity', 0)
      .on('end', () ->
        d3.select(@)
          .style('display', 'none')
      )

class App.D3Chart.ZipMap extends App.D3Chart.ResponsiveBase
  constructor: (container_selector, legend_selector, zoom_in_selector, zoom_out_selector, json_path, data) ->
    @container_selector = container_selector
    @_reset()
    super(container_selector, {top: 20, right: 20, left: 20, bottom: 20})
    @zoom_in = d3.select(zoom_in_selector)
    @zoom_out = d3.select(zoom_out_selector)
    @tooltip = new App.D3Chart.InitiativeToolTip('#d3-tooltip')
    @legend = d3.select(legend_selector)
    @json_path = json_path
    @data = data.data
    @values = Object.keys(@data).map((d) =>
      @data[d]
    )
    @keys = data.keys
    @scale = {
      rainbowFill: d3.scaleSequential().domain([0, @keys.length]).interpolator(d3.interpolateViridis),
      radius: d3.scaleSqrt().domain(d3.extent(@values)).range([3, 8]);
    }
    @zip3Data = []
    Object.keys(@data).forEach((d) =>
      k = d.split('__')
      zip = k[1]
      @zip3Data.push({zip: zip, type: k[0], value: @data[d]})
    )
    @projection = d3.geoAlbersUsa()
      .scale(1000)
      .translate([@dimensions.width/2, @dimensions.height/2]);
    @path = d3.geoPath().projection(@projection);
    @zoom = d3.zoom().scaleExtent([1, 8]).on("zoom", () =>
      @chart.attr('transform', d3.event.transform)
    )
    @svg.call(@zoom)

  _drawLegend: () ->
    @legend.selectAll('div.loso__legend-item')
      .data(@keys)
      .enter()
      .append('div')
        .attr('class', 'loso__legend-item')
        .text((d) => d)
        .append('div')
          .attr('class', 'loso__legend-item-color')
          .attr('style', (d) => 'background-color:'+@scale.rainbowFill(@keys.indexOf(d)))

  draw: () ->
    @_drawLegend()
    @zoom_in.on('click', () =>
      @zoom.scaleBy(@svg, 2);
    )
    @zoom_out.on('click', () =>
      @zoom.scaleBy(@svg, 1/2);
    )
    d3.json(@json_path, (error, us) =>
      groupedTopo = d3.nest()
        .key((d) => 
          d.properties.ZIP
        )
        .entries(topojson.feature(us, us.objects.zip3).features)
      @zipData = []
      groupedTopo.forEach((d) =>
        matches = @zip3Data.filter((z) ->
          z.zip.substring(0, 3) == d.key
        )
        matches.forEach((m) =>
          m.topo = d.values.filter((d) =>
            if @path(d) then true else false
          )
          @zipData.push(m)
        )
      )

      @chart.append("g")
        .attr("class", "zips")
        .selectAll("path")
        .data(topojson.feature(us, us.objects.zip3).features)
        .enter().append("path")
          .attr("d", @path)
          .attr('fill', '#f2f2f2')
          .attr('stroke', '#cccccc')
          .attr('stroke-width', '0.5px')
          .style('cursor', 'pointer')
      @chart.append('g')
        .attr('class', 'dots')
          .selectAll('circle')
          .data(@zipData)
          .enter().append('circle')
            .attr('cx', (d) =>
              @path.centroid(d.topo[0])[0]
            )
            .attr('cy', (d) =>
              @path.centroid(d.topo[0])[1]
            )
            .attr('r', (d) =>
              @scale.radius(d.value)
            )
            .attr('fill', (d) =>
              k = @keys.indexOf(d.type)
              @scale.rainbowFill(k)
            )
            .attr('opacity', '0.8')
            .on('mouseover', (d) =>
              data = [d.type, d.zip, d.value]
              currentItems = @tooltip.element().selectAll('div')
                .data(data)
                
              currentItems.exit().remove()

              newItems = currentItems.enter()
                .append('div')

              items = newItems.merge(currentItems)
                .attr('class', (d, i) =>
                  if i == 0
                    'd3-tooltip__item'
                )
                .html((d, i) => 
                  if i == 0
                    k = @keys.indexOf(d)
                    '<span class="d3-tooltip__swatch" style="background-color:'+@scale.rainbowFill(k)+';"></span><span>'+d+'</span>'
                  else if i == 1
                    'Zipcode: <b>'+d+'</b>'
                  else
                    'Count: <b>'+d+'</b>'
                )

              @tooltip.show(d)
            )
            .on('mouseout', (d) => @tooltip.hide(d))
    )

class App.D3Chart.Pie extends App.D3Chart.ResponsiveBase
  constructor: (container_selector, table_selector, legend_selector, data, report_range_dates, comparison_range_dates) ->
    @container_selector = container_selector
    @_reset()
    super(container_selector, {top: 20, right: 0, left: 20, bottom: 20})
    @tooltip = new App.D3Chart.InitiativeToolTip('#d3-tooltip')
    @legend = d3.select(legend_selector)
    @chart.attr("transform", "translate(" + @dimensions.width / 2 + "," + @dimensions.height / 2 + ")")
    @radius = d3.min([@dimensions.width, @dimensions.height])/2
    @report_range_dates = report_range_dates
    @comparison_range_dates = comparison_range_dates
    @_loadHelpers()
    @_loadData(data)
    
    @scale = {
      rainbowFill: d3.scaleSequential().domain([0, @keys.length]).interpolator(d3.interpolateViridis),
      outerFill: d3.scaleSequential().domain([0, @outerKeys.length]).interpolator(d3.interpolateWarm)
    }
    @table = new App.D3Chart.ColorCodedTable(table_selector, @outerKeys, @scale.outerFill)
    @table2 = new App.D3Chart.ColorCodedTable(table_selector+'-more-details', @keys, @scale.rainbowFill)

  _loadData: (data) ->
    @keys = data.keys
    @data = data.data
    @total_count = 0
    @all_totals = []
    @bucket_totals = Object.keys(@data).map((k) =>
      @total_count += @data[k].total
      d = [k, @data[k].total]
      Object.keys(@data[k])
        .filter((k2) =>
          k2 != 'total'
        )
        .forEach((k2) =>
          @all_totals.push([k2, @data[k][k2], k])
        )
      d
    )
    @outerKeys = d3.nest().key((d) => d[0])
      .entries(@bucket_totals)
      .map((d) => d.key)

  _loadHelpers: () ->
    @path = d3.arc()
      .outerRadius(@radius - 10)
      .innerRadius(0);
    @innerPath = d3.arc()
      .outerRadius(@radius - 30)
      .innerRadius(0)
    @pie = d3.pie()
      .sort(null)
      .value((d) => d[1])

  _drawLegend: () ->
    @legend.selectAll('div.loso__legend-item')
      .data(@keys)
      .enter()
      .append('div')
        .attr('class', 'loso__legend-item clearfix')
        .text((d) => 
          if d == 'report'
            "Report Period (#{@report_range_dates})"
          else if d == 'comparison'
            "Comparison Period (#{@comparison_range_dates})"
          else 
            d
        )
        .append('div')
          .attr('class', 'loso__legend-item-color')
          .attr('style', (d) =>
            'background-color:'+@scale.rainbowFill(@keys.indexOf(d))
          )

  _drawToolTip: (data, scale, keys) ->
    currentItems = @tooltip.element().selectAll('div')
      .data(data)
      
    currentItems.exit().remove()

    newItems = currentItems.enter()
      .append('div')

    items = newItems.merge(currentItems)
      .attr('class', (d, i) =>
        if i == 0
          'd3-tooltip__item'
      )
      .html((d, i) => 
        if i == 0
          k = keys.indexOf(d)
          '<span class="d3-tooltip__swatch" style="background-color:'+scale(k)+';"></span><span>'+d+'</span>'
        else
          'Count: <b>'+d+'</b>'
      )


  draw: () ->
    arc = @chart.selectAll(".arc")
      .data(@pie(@bucket_totals))
      .enter().append("g")
        .attr("class", "arc");

    arc.append("path")
      .attr("d", @path)
      .attr('fill', (d, i) =>
        key = d.data[0]
        @scale.outerFill(@outerKeys.indexOf(key))
      )
      .attr('stroke', (d) => 'white')
      .attr('stroke-width', '2px')
      .on('mouseover', (d) =>
        data = d.data
        @_drawToolTip(data, @scale.outerFill, @outerKeys)
        @tooltip.show(d)
      )
      .on('mouseout', (d) => @tooltip.hide(d))

    innerArc = @chart.selectAll('.arc2')
      .data(@pie(@all_totals))
      .enter().append('g')
        .attr('class', 'arc2')

    innerArc.append('path')
      .attr('d', @innerPath)
      .attr('fill', (d) =>
        key = d.data[0]
        @scale.rainbowFill(@keys.indexOf(key))
      )
      .attr('stroke', (d) => 'white')
      .attr('stroke-width', '2px')
      .on('mouseover', (d) =>
        data = [d.data[0], d.data[1]]
        @_drawToolTip(data, @scale.rainbowFill, @keys)
        @tooltip.show(d)
      )
      .on('mouseout', (d) => @tooltip.hide(d))

    @table.drawTableColors()
    @table2.drawTableColors()
    @_drawLegend()


class App.D3Chart.InitiativeLine extends App.D3Chart.ResponsiveBase
  constructor: (container_selector, legend_selector, table_selector, margin, data) ->
    @container_selector = container_selector
    @_reset()
    @legend = d3.select(legend_selector)
    @data = []
    @dates = []
    @values = []
    @_loadData(data)
    @_drawLegend()
    @_resizeContainer()
    super(container_selector, margin)
    @range = @_loadRange()
    @domain = @_loadDomain()
    @scale = @_loadScale()
    @table = new App.D3Chart.ColorCodedTable(table_selector, @keys, @scale.rainbowFill)

  _resizeContainer: () ->
    container = d3.select(@container_selector)
    l_height = @legend.node().getBoundingClientRect().height
    c_height = container.node().getBoundingClientRect().height
    if l_height > c_height
      container.node().style.height = l_height+'px'

  _loadData: (data) ->
    data.forEach((d) =>
      @values.push(d[2])
      date = new Date(d[1])
      @dates.push(date)
      d.push(date)
      @data.push(d)
    )
    @grouped = d3.nest().key((d) => d[0])
      .entries(@data)
    @rainbowFillScale = d3.scaleSequential().domain([0, @grouped.length]).interpolator(d3.interpolateViridis)
    @keys = @grouped.map((d) => d.key)


  _loadRange: () ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0]
    }

  _loadDomain: () ->
    {
      x: d3.extent(@dates),
      y: [0, d3.extent(@values)[1]],
      rainbowFill: [0, @grouped.length]
    }

  _loadScale: () ->
    {
      x: d3.scaleTime().domain(@domain.x).range(@range.x),
      y: d3.scaleLinear().domain(@domain.y).range(@range.y),
      rainbowFill: @rainbowFillScale
    }

  _drawLegend: () ->
    @legend.selectAll('div.nc-legend__item')
      .data(@grouped)
      .enter()
      .append('div')
        .attr('class', 'nc-legend__item')
        .text((d) => d.key)
        .append('div')
        .attr('class', 'nc-legend__item-color')
        .attr('style', (d) => 'background-color:'+@rainbowFillScale(@keys.indexOf(d.key)))

  _initLegendHover: () ->
    that = this
    @legend.selectAll('div.nc-legend__item')
      .on('mouseover', (d) ->
        lineGenerator = d3.line()
        item = d3.select(this)
        d = item.node().__data__
        that.chart.append('rect')
          .attr('class', 'overlay')
          .attr('x', that.scale.x(that.domain.x[0]))
          .attr('y', that.scale.y(that.domain.y[1])-1)
          .attr('width', that.scale.x(that.domain.x[1]) - that.scale.x(that.domain.x[0]))
          .attr('height', that.scale.y(that.domain.y[0]) - that.scale.y(that.domain.y[1])+2)
          .attr('fill', '#ffffff')
          .attr('opacity', '0')
          .transition().duration(500)
            .attr('opacity', '0.9')
        that.chart.selectAll('path.focus-line')
          .data([d])
          .enter()
          .append('path')
            .attr('class', 'focus-line')
            .attr('d', (d) =>
              line = d.values.sort((x, y) => d3.ascending(x[3], y[3]))
              line = line.map((x) => [that.scale.x(x[3]), that.scale.y(x[2])])
              lineGenerator(line)
            )
            .attr('stroke', (d) => that.scale.rainbowFill(that.keys.indexOf(d.key)))
            .attr('stroke-width', '0px')
            .attr('fill', 'transparent')
            .transition().duration(500)
              .attr('stroke-width', '2px')
      )
      .on('mouseout', (d) ->
        that.chart.selectAll('rect.overlay').remove()
        that.chart.selectAll('path.focus-line').remove()
      )

  _drawAxis: () ->
    ticks = if @domain.y[1] > 20 then 10 else @domain.y[1]
    xAxis = d3.axisBottom()
      .scale(@scale.x)
    yAxis = d3.axisLeft()
      .ticks(ticks)
      .tickFormat(d3.format(",d"))
      .scale(@scale.y)
    @chart.append('g')
      .attr('class', 'xAxis')
      .attr('transform', 'translate(0,'+(@dimensions.height+1)+')')
      .call(xAxis)
    @chart.append('g')
      .attr('class', 'yAxis')
      .call(yAxis)

  _drawLines: () ->
    lineGenerator = d3.line()
    @chart.selectAll('g.line')
      .data(@grouped)
      .enter()
      .append('g')
        .attr('class', 'line')
        .selectAll('path')
          .data((d) => [d])
          .enter()
          .append('path')
            .attr('d', (d) =>
              line = d.values.sort((x, y) => d3.ascending(x[3], y[3]))
              line = line.map((x) => [@scale.x(x[3]), @scale.y(x[2])])
              lineGenerator(line)
            )
            .attr('stroke', (d) => @scale.rainbowFill(@keys.indexOf(d.key)))
            .attr('stroke-width', '2px')
            .attr('fill', 'transparent')
 
  draw: () ->
    @_drawAxis()
    @_drawLines()
    @_initLegendHover()
    @table.drawTableColors()
      



class App.D3Chart.InitiativeStackedBar extends App.D3Chart.ResponsiveBase
  
  constructor: (container_selector, table_selector, legend_selector, margin, data, report_range_dates, comparison_range_dates) ->
    @data = data
    @tooltip = new App.D3Chart.InitiativeToolTip('#d3-tooltip')
    @container_selector = container_selector
    @_reset()
    @margin = margin
    @report_range_dates = report_range_dates
    @comparison_range_dates = comparison_range_dates
    @_resizeContainer()
    super(container_selector, margin)
    @range = @_loadRange()
    @domain = @_loadDomain()
    @scale = @_loadScale()
    if table_selector
      @table = d3.select(table_selector)
    if legend_selector
      @legend = d3.select(legend_selector)
  
  _resizeContainer: ()->
    @labelHeight = if @data.keys[0] == 'count' then 0 else 22
    @barHeight = 12
    container = d3.select(@container_selector)
    height = @data.keys.length * ((@data.types.length*@barHeight)+@labelHeight) + @margin.top + @margin.bottom
    container.node().style.height = height+'px'

  _loadDomain: () ->
    {
      x: [0, d3.max(@data.values)],
      y: @data.keys,
      rainbowFill: [0, @data.types.length]
    }

  _loadRange: () ->
    {
      x: [0, @dimensions.width],
      y: [@dimensions.height, 0]
    }

  _loadScale: () ->
    {
      x: d3.scaleLinear().domain(@domain.x).range(@range.x),
      y: d3.scaleBand().domain(@domain.y).range(@range.y)
      rainbowFill: d3.scaleSequential().domain(@domain.rainbowFill).interpolator(d3.interpolateViridis)
    }

  _drawAxis: () ->
    ticks = if @domain.x[1] > 20 then 10 else @domain.x[1]
    xAxisTop = d3.axisTop()
      .scale(@scale.x)
      .ticks(ticks)
      .tickFormat(d3.format(",d"))
    xAxisBottom = d3.axisBottom()
      .scale(@scale.x)
      .ticks(ticks)
      .tickFormat(d3.format(",d"))
    @chart.append('g')
      .attr('class', 'xAxis')
      .attr('transform', 'translate(0,-1)')
      .call(xAxisTop)
    @chart.append('g')
      .attr('class', 'xAxis')
      .attr('transform', 'translate(0,'+(@dimensions.height+1)+')')
      .call(xAxisBottom)

  _groupData: (d, i) ->
    data = []
    Object.keys(d).forEach((x) =>
      if x != 'type'
        data.push([x, d[x], d.type])
    )
    data

  _transformGroup: (d, i) ->
    t = if i == 0 then @labelHeight else (@labelHeight + (@barHeight*i))
    'translate(0,'+t+')'

  _drawToolTip: (data) ->
    data = [data[0], data[2], data[1]]
    currentItems = @tooltip.element().selectAll('div')
      .data(data)
      
    currentItems.exit().remove()

    newItems = currentItems.enter()
      .append('div')

    items = newItems.merge(currentItems)
      .attr('class', (d, i) =>
        if i == 1
          'd3-tooltip__item'
      )
      .html((d, i) => 
        if i == 0
          '<b>'+@data.labels[d]+'</b>'
        else if i == 1
          '<span class="d3-tooltip__swatch" style="background-color:'+@scale.rainbowFill(@data.types.indexOf(d))+';"></span><span>'+d+'</span>'
        else
          '<b>'+d+'</b>'
      )
  
  _drawOutlines: () ->
    @chart.selectAll('g.outlines')
      .data(@data.data)
      .enter()
      .append('g')
        .attr('class', 'outlines')
        .attr('transform', (d, i) => @_transformGroup(d, i))
        .selectAll('rect')
          .data((d, i) => 
            # console.log(d)
            @_groupData(d, i)
          )
          .enter()
          .append('rect')
            .attr('x', (d) => @scale.x(0))
            .attr('y', (d) => @scale.y(d[0]))
            .attr('width', (d) => @scale.x(@domain.x[1])-@scale.x(0))
            .attr('height', (d) => @barHeight)
            .attr('stroke', '#d2d2d2')
            .attr('stroke-width', '1px')
            .attr('fill', '#ffffff')
            .on('mouseover', (d) =>
              @_drawToolTip(d)
              @tooltip.show(d)
            )
            .on('mouseout', (d) => @tooltip.hide(d))

  _drawBars: () ->
    @chart.selectAll('g.bars')
      .data(@data.data)
      .enter()
      .append('g')
        .attr('class', 'bars')
        .attr('fill', (d) => @scale.rainbowFill(@data.types.indexOf(d.type)))
        .attr('transform', (d, i) => @_transformGroup(d, i))
        .selectAll('rect')
          .data((d, i) => @_groupData(d, i))
          .enter()
          .append('rect')
            .attr('x', (d) => @scale.x(0))
            .attr('y', (d) => @scale.y(d[0]))
            .attr('width', (d) => @scale.x(d[1])-@scale.x(0))
            .attr('height', (d) => @barHeight)
            .on('mouseover', (d) =>
              @_drawToolTip(d)
              @tooltip.show(d)
            )
            .on('mouseout', (d) => @tooltip.hide(d))

  _drawValues: () ->
    @chart.selectAll('g.values')
      .data(@data.data)
      .enter()
      .append('g')
        .attr('class', 'values')
        .attr('transform', (d, i) => @_transformGroup(d, i))
        .selectAll('text')
          .data((d, i) => @_groupData(d, i))
          .enter()
          .append('text')
            .attr('x', (d) => @scale.x(d[1])+3)
            .attr('y', (d) => @scale.y(d[0])+(@barHeight/2))
            .attr('style', 'font-size:10px;')
            .attr('alignment-baseline', 'central')
            .text((d) => d[1])

  _drawMarker: () ->
    @chart.selectAll('g.markers')
      .data(@data.data)
      .enter()
      .append('g')
        .attr('class', 'markers')
        .attr('fill', (d) => @scale.rainbowFill(@data.types.indexOf(d.type)))
        .attr('transform', (d, i) => @_transformGroup(d, i))
        .selectAll('rect')
          .data((d, i) => @_groupData(d, i))
          .enter()
          .append('rect')
            .attr('transform', 'translate(-'+(@barHeight/2)+', 0)')
            .attr('x', (d) => @scale.x(0))
            .attr('y', (d) => @scale.y(d[0]))
            .attr('width', (d) => @barHeight/2)
            .attr('height', (d) => @barHeight)          

  _drawLabels: () ->
    @chart.selectAll('text.label')
      .data(@data.keys)
      .enter()
      .append('text')
        .attr('class', 'label')
        .attr('x', (d) => @scale.x(0))
        .attr('y', (d) => @scale.y(d))
        .attr('transform', (d, i) => 'translate(0,'+(@labelHeight/2)+')')
        .attr('alignment-baseline', 'central')
        .text((d) => @data.labels[d])

  _drawBands: () ->
    @chart.selectAll('rect.band')
      .data(@data.keys)
      .enter()
      .append('rect')
        .attr('class', 'band')
        .attr('x', (d) => @scale.x(0))
        .attr('y', (d) => @scale.y(d))
        .attr('width', (d) => @scale.x(@domain.x[1])-@scale.x(0))
        .attr('height', (d) => @scale.y.bandwidth())
        .attr('fill', '#f2f2f2') 

  _drawTable: () ->
    that = @
    @table.selectAll('th[data-d3-key]').each(() ->
      ele = d3.select(this)
      d = ele.node().getAttribute('data-d3-key')
      ele.append('span')
        .attr('style', 'background-color: '+that.scale.rainbowFill(that.data.types.indexOf(d)))
    )

  _drawLegend: () ->
    @legend.selectAll('div.loso__legend-item')
      .data(@data.types)
      .enter()
      .append('div')
        .attr('class', 'loso__legend-item clearfix')
        .text((d) => 
          if d == 'report'
            "Report Period (#{@report_range_dates})"
          else if d == 'comparison'
            "Comparison Period (#{@comparison_range_dates})"
          else 
            d
        )
        .append('div')
          .attr('class', 'loso__legend-item-color')
          .attr('style', (d) =>
            'background-color:'+@scale.rainbowFill(@.data.types.indexOf(d))
          )

  draw: () ->
    @_drawBands()
    @_drawAxis()
    if @labelHeight > 0
      @_drawLabels()
    @_drawMarker()
    @_drawOutlines()
    @_drawBars()
    @_drawValues()
    if @table
      @_drawTable()
    if @legend
      @_drawLegend()

class App.D3Chart.InitiativeStackedSummaryBar extends App.D3Chart.InitiativeStackedBar
  _loadScale: () ->
    {
      x: d3.scaleLinear().domain(@domain.x).range(@range.x),
      y: d3.scaleBand().domain(@domain.y).range(@range.y)
      rainbowFill: d3.scaleSequential().domain(@domain.rainbowFill).interpolator(d3.interpolateYlOrRd)
    }