# frozen_string_literal: true
module Blacklight::Solr::Response::PaginationMethods
  include Kaminari::PageScopeMethods
  include Kaminari::ConfigurationMethods::ClassMethods

  def limit_value #:nodoc:
    rows
  end
#use start from group response if it is greater than start in solr response
  def offset_value #:nodoc:
    start == 0 && !@group.nil? && @group['groups'][0]['doclist']['start'] > 0 ? @group['groups'][0]['doclist']['start'] : start
  end
# if a single group is returned, use its matches value instead of total
  def total_count #:nodoc:
    total == 1 && !@group.nil? && @group['matches'] > 1 ? @group['matches'] : total
  end
end
