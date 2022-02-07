###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientMatchHelper
  def data_qaulity_warning(type, value)
    return '' if value.blank? || [1, 99].include?(value.to_i)

    label = HUD.send("#{type.downcase}_data_quality", value)
    content_tag :abbr, title: label do
      '!!'
    end
  end

  def client_match_scorecard(match)
    controller.render_to_string(match)
  end

  def match_contribution_flags(match, fields)
    exact_match = Array(fields).all? do |fld|
      match.destination_client.send(fld) == match.source_client.send(fld)
    end
    match_flag(match.score_contribution(fields), exact_match)
  end

  private def match_flag(score, exact_match, threshold: 2)
    return '' unless score.present? || exact_match

    # http://colorbrewer2.org/#type=diverging&scheme=RdYlGn&n=5
    color, icon, color2, title = if score.nil? || score.abs < threshold.abs / 2
      ['#dddddd', "\u00A0~", '#ffffff', 'neutral']
    elsif score < -threshold.abs
      ['#1a9641', '++', '#ffffff', 'strong evidence for']
    elsif score.negative?
      ['#a6d96a', "\u00A0+", '#000000', 'evidence for']
    elsif score < threshold.abs
      ['#fdae61', "\u00A0-", '#000000', 'evidence against']
    else
      ['#d7191c', '--', '#ffffff', 'strong against']
    end
    title = "#{title}/exact match" if exact_match
    title = "#{title}: #{score.round(2)}" if score
    content_tag(:abbr, title: title, style: "font-family: monospace; border-radius: 4px; font-weight: bold; background-color:#{color}; color:#{color2}; padding:1px 2px; margin:1px;") do
      exact_match ? icon.gsub(/[-+~]/, '=') : icon
    end
  end

  def match_legend
    [
      [match_flag(-10, true), 'Exact match - strong evidence for'],
      [match_flag(-10, false), 'Strong evidence for'],
      [match_flag(-1, true), 'Exact match - evidence for'],
      [match_flag(-1, false), 'Evidence for'],
      [match_flag(0, true), 'Exact match - neutral'],
      [match_flag(0, false), 'Neutral'],
      [match_flag(1, false), 'Evidence against'],
      # [match_flag(1, true), 'Exact match/Evidence against'],
      [match_flag(10, false), 'Strong evidence against'],
      # [match_flag(10, true), 'Exact match/Strong evidence against'],
    ].map do |icon, text|
      "#{raw icon}: #{text}"
    end.join('<br/>').html_safe
  end
end
