# frozen_string_literal: true
module Blacklight::Solr::Response::Response
  def response
    self[:response] || {}
  end

  # short cut to response['numFound']
  def total
    #use group matches instead of numFound for grouped response
    if response[:numFound].nil? 
      self[:grouped][blacklight_config['index']['group']]['matches'].to_s.to_i 
    else 
      response[:numFound].to_s.to_i
    end
  end

  def start
    response[:start].to_s.to_i
  end

  def empty?
    total.zero?
  end
end
