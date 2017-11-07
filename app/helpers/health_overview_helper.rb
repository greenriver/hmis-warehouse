module HealthOverviewHelper

  TOP_CHART_LABELS = {
    top_providers: 'of Total Cost',
    top_conditions: 'of Med/BH Cost',
    top_ip_conditions: 'of IP Cost'
  }

  TOP_CHART_HINTS = {
    top_providers: ' (All Claims)',
    top_conditions: ' (Medical/BH Claims Only)'
  }

  TOP_CHART_TITLES = {
    top_providers: 'Top Providers',
    top_conditions: 'Top Clinical Conditions',
    top_ip_conditions: 'Top Inpatient Conditions'
  }

  CHART_COLORS = {
    all: ['#008DA8'],
    patient: ['#00549E', '#777777']
  }

  PATH_BASE = {
    all: '/api/health/claims/',
    patient: '/api/health/claims/patients/'
  }

  def d3_container_header(data_type, other_text, just_patient: false)
    colors = CHART_COLORS[data_type.to_sym]
    if just_patient
      colors = [colors[0]]
    end
    content_tag :div, class: 'ho-container__header' do
      colors.each_with_index do |color, index|
        concat d3_container_header_key(color, index, data_type, other_text)
      end
    end
  end

  def d3_container_header_key(color, index, data_type, other_text)
    style = index == 0 ? "color: #{color}; font-weight: bold;" : "color: #{color};"
    icon = d3_container_header_icon(data_type, index)
    text = (index == 0 && data_type == 'patient') ? @patient.client.name : other_text
    content_tag :div, class: 'ho-compare__key', style: style do
      concat content_tag :i, '', class: icon
      concat " #{text}"
    end
  end

  def d3_container_header_icon(data_type, index)
    if data_type == 'all' || index != 0
      'icon-users'
    else
      'icon-user' 
    end
  end

  def d3_chart_path(data, data_type)
    data_key = data_type.to_sym
    data_type == 'all' ? "#{PATH_BASE[data_key]}#{data}" : "#{PATH_BASE[data_key]}#{@patient.id}/#{data}"
  end

  def d3_base_chart(css_class, date_css_class, title)
    data = {dates: ".#{date_css_class}"}
    content_tag :div, class: css_class, data: data do
      d3_base_chart_title(date_css_class, title)
    end
  end

  def d3_base_chart_title(css_class, title)
    content_tag :h4 do
      concat title
      concat content_tag :small, '', class: css_class
    end
  end

  def d3_top_chart(data, data_type)
    data_key = data.to_sym
    path = d3_chart_path(data, data_type)
    y_attr = data == 'top_providers' ? 'provider_name' : 'description'
    chart_data = {url: path, yattr: y_attr, ylabel: TOP_CHART_LABELS[data_key], maintype: data_type.to_s}
    content_tag :div, class: 'd3-top__chart', id: data, data: chart_data do
      concat d3_top_chart_title(data_key)
    end
  end

  def d3_top_chart_title(data_key)
    title = TOP_CHART_TITLES[data_key]
    hint = TOP_CHART_HINTS[data_key]
    content_tag :h4 do
      concat content_tag :span, title
      if hint
        concat content_tag :small, hint
      end
    end
  end

  def d3_trend_chart(data, data_type)
    path = d3_chart_path(data, data_type)
    content_tag :div, '', class: 'd3-chart d3-claims__chart', id: "claims__#{data}", data: {url: path}
  end

  def key_metrics_table_header(key)
    key = key.to_s
    marker = {
      'ED_Visits'=> 'ed-visits', 
      'IP_Admits'=>'ip-admits',
      'Average_Days_to_Readmit'=>'readmit'
    }
    content_tag :th do
      if marker[key]
        concat content_tag :div, '', class: "ho-compare__th-marker #{marker[key]}"
      end
      concat key.gsub('_', ' ')
      if key == 'ED_Visits' || key == 'IP_Admits'
        concat content_tag :small, '(past 6 months)'
      end
    end
  end

  def compare_box(key, patient_cost, sdh_cost, variance=nil)
    content_tag :div, class: 'ho-compare-box' do
      concat content_tag :div, key.to_s.gsub('_', ' '), class: 'ho-compare-box__label'
      concat content_tag :div, patient_cost[key], class: 'ho-compare-box__content'
      concat content_tag :div, sdh_cost[key], class: 'ho-compare-box__to'
      if variance
        concat "Variance: #{variance[key]}" 
      else
        concat ' &nbsp;'.html_safe
      end
    end
  end

  def housing_status_hint(key)
    css_class = "ho-hint__swatch #{key.gsub(' ', '-')}"
    ho_hint(css_class, key.titleize())
  end

  def key_metrics_table_hint(key)
    key = key.to_s
    marker = {
      'ED_Visits'=> 'ed-visits', 
      'IP_Admits'=>'ip-admits',
      'Average_Days_to_Readmit'=>'readmit'
    }
    text = {
      'ED_Visits'=> 'ED Visits that did not result in IP Admissions', 
      'IP_Admits'=>'Acute IP Admissions only (i.e. no SNF/Rehab/Respite/Psych)',
      'Average_Days_to_Readmit'=>'For readmits, average only for those who had at least two admissions'
    }
    if marker[key]
      css_class = "ho-compare__marker #{marker[key]}"
      ho_hint(css_class, text[key])
    end
  end

  def ho_hint(css_class, text)
    content_tag :div, class: "ho-hint" do
      concat content_tag :div, '', class: css_class
      concat content_tag :small, text
    end
  end

end