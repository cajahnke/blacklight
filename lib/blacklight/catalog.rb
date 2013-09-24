# -*- encoding : utf-8 -*-
module Blacklight::Catalog   
  extend ActiveSupport::Concern
  
  include Blacklight::Base
  
  SearchHistoryWindow = 12 # how many searches to save in session history

  # The following code is executed when someone includes blacklight::catalog in their
  # own controller.
  included do
    helper_method :current_search_session, :search_session
    helper_method :sms_mappings
    before_filter :search_session, :history_session
    before_filter :add_current_search_to_session, :only => :index

    # Whenever an action raises SolrHelper::InvalidSolrID, this block gets executed.
    # Hint: the SolrHelper #get_solr_response_for_doc_id method raises this error,
    # which is used in the #show action here.
    rescue_from Blacklight::Exceptions::InvalidSolrID, :with => :invalid_solr_id_error
  end
  
    # get search results from the solr index
    def index
      
      (@response, @document_list) = get_search_results
      @filters = params[:f] || []
      
      respond_to do |format|
        format.html { 
          extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => t('blacklight.search.rss_feed') )
          extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => t('blacklight.search.atom_feed') )
        }
        format.rss  { render :layout => false }
        format.atom { render :layout => false }

        
        format.json do
          render json: render_search_results_as_json
        end
      end
    end
    
    # get single document from the solr index
    def show
      @response, @document = get_solr_response_for_doc_id    

      respond_to do |format|
        format.html {setup_next_and_previous_documents}

        format.json { render json: {response: {document: @document}}}

        # Add all dynamically added (such as by document extensions)
        # export formats.
        @document.export_formats.each_key do | format_name |
          # It's important that the argument to send be a symbol;
          # if it's a string, it makes Rails unhappy for unclear reasons. 
          format.send(format_name.to_sym) { render :text => @document.export_as(format_name), :layout => false }
        end
        
      end
    end

    # updates the search counter (allows the show view to paginate)
    def update
      search_session[:id] = params[:search_id]
      search_session[:counter] = params[:counter]
      redirect_to :action => "show"
    end
    
    # displays values and pagination links for a single facet field
    def facet
      @pagination = get_facet_pagination(params[:id], params)

      respond_to do |format|
        # Draw the facet selector for users who have javascript disabled:
        format.html 
        format.json { render json: render_facet_list_as_json }

        # Draw the partial for the "more" facet modal window:
        format.js { render :layout => false }
      end
    end
    
    # method to serve up XML OpenSearch description and JSON autocomplete response
    def opensearch
      respond_to do |format|
        format.xml do
          render :layout => false
        end
        format.json do
          render :json => get_opensearch_response
        end
      end
    end
    
    # citation action
    def citation
      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
      respond_to do |format|
        format.html
        format.js { render :layout => false }
      end
    end
    # grabs a bunch of documents to export to endnote
    def endnote
      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
      respond_to do |format|
        format.endnote { render :layout => false }
      end
    end
    
    # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
    def email
      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
      
      if request.post? and validate_email_params
        email = RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message]}, url_options)
        email.deliver 

        flash[:success] = I18n.t("blacklight.email.success")

        respond_to do |format|
          format.html { redirect_to catalog_path(params['id']) }
          format.js { render 'email_sent' }
        end and return
      end

      respond_to do |format|
        format.html
        format.js { render :layout => false }
      end
    end

    
    # SMS action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
    def sms 
      @response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
      
      if request.post? and validate_sms_params
        to = "#{params[:to].gsub(/[^\d]/, '')}@#{sms_mappings[params[:carrier]]}"

        sms = RecordMailer.sms_record(@documents, { :to => to }, url_options)
        sms.deliver

        flash[:success] = I18n.t("blacklight.sms.success")

        respond_to do |format|
          format.html { redirect_to catalog_path(params['id']) }
          format.js { render 'sms_sent' }
        end and return
      end
        
      respond_to do |format|
        format.js { render :layout => false }
        format.html
      end
    end
    
    def librarian_view
      @response, @document = get_solr_response_for_doc_id

      respond_to do |format|
        format.html
        format.js { render :layout => false }
      end
    end
    
    
    protected    
    #
    # non-routable methods ->
    #

    # override this method to change the JSON response from #index 
    def render_search_results_as_json
      {response: {docs: @document_list, facets: search_facets_as_json, pages: pagination_info(@response)}}
    end

    def search_facets_as_json
      facets_from_request.as_json.each do |f|
        f["label"] = facet_configuration_for_field(f["name"]).label
        f["items"] = f["items"].as_json.each do |i|
          i['label'] ||= i['value']
        end
      end 
    end

    # override this method to change the JSON response from #facet 
    def render_facet_list_as_json
      {response: {facets: @pagination }}
    end

    # Overrides the Blacklight::Controller provided #search_action_url.
    # By default, any search action from a Blacklight::Catalog controller
    # should use the current controller when constructing the route.
    def search_action_url options = {}
      url_for(options.merge(:action => 'index', :only_path => true))
    end

    # calls setup_previous_document then setup_next_document.
    # used in the show action for single view pagination.
    def setup_next_and_previous_documents
      if search_session[:counter] and current_search_session
        index = search_session[:counter].to_i - 1
        response, documents = get_previous_and_next_documents_for_search index, current_search_session.query_params

        search_session[:total] = response.total
        @search_context_response = response
        @previous_document = documents.first
        @next_document = documents.last
      end
    end
    
    # gets a document based on its position within a resultset  
    def setup_document_by_counter(counter)
      ActiveSupport::Deprecation.warn("#setup_document_by_counter helper is deprecated in Blacklight 4.x and will be removed")

      return if counter < 1 or current_search_session.nil?
      get_single_doc_via_search(counter, current_search_session.query_params)
    end
    
    def setup_previous_document
      ActiveSupport::Deprecation.warn("#setup_previous_document helper was deprecated in Blacklight 4.x; now happens automatically as part of #setup_next_and_previous_documents")
    end
    
    def setup_next_document
      ActiveSupport::Deprecation.warn("#setup_next_document helper was deprecated in Blacklight 4.x; now happens automatically as part of #setup_next_and_previous_documents")
    end
    
    # sets up the session[:history] hash if it doesn't already exist.
    # assigns all Search objects (that match the searches in session[:history]) to a variable @searches.
    def history_session
      session[:history] ||= []
      @searches = searches_from_history # <- in BlacklightController
    end

    def delete_or_assign_search_session_params
     # deprecated in blacklight 4.x
      ActiveSupport::Deprecation.warn("#delete_or_assign_search_session_params helper was deprecated in Blacklight 4.x; now happens automatically as part of #current_search_session")
    end
    
    def save_current_search_params    
     # deprecated in blacklight 4.x
      ActiveSupport::Deprecation.warn("#save_current_search_params helper was deprecated in Blacklight 4.x; now happens automatically as part of #current_search_session")
    end

    # sets up the session[:search] hash if it doesn't already exist
    def search_session
      session[:search] ||= {}
    end

    def add_current_search_to_session
      if current_search_session
        search_session[:id] = current_search_session.id
      end
    end
    
    # The current search session 
    def current_search_session

      if action_name == "index"
        params_copy = params.reject { |k,v| blacklisted_search_session_params.include?(k.to_sym) or v.blank? }

        return if params_copy.reject { |k,v| [:action, :controller].include? k.to_sym }.blank?
        
        saved_search = searches_from_history.select { |x| x.query_params == params_copy }.first

        saved_search ||= begin
          s = Search.create(:query_params => params_copy)
          add_to_search_history(s)
          s
        end
      elsif params[:search_id] and !params[:search_id].blank?
        searches_from_history.find(params[:search_id]) rescue nil
      elsif search_session[:id]
        searches_from_history.find(search_session[:id]) rescue nil
      end

    end
    
    # Add a search to the in-session search history list
    def add_to_search_history search
      session[:history] ||= []

      session[:history].unshift(search.id)

      if session[:history].length > blacklight_config.search_history_window

        session[:history] = session[:history].slice(0, blacklight_config.search_history_window )
        
      end
    end

    # A list of query parameters that should not be persisted for a search      
    def blacklisted_search_session_params
      [:commit, :counter, :total, :search_id]
    end

    # sets some additional search metadata so that the show view can display it.
    def set_additional_search_session_values
      ActiveSupport::Deprecation.warn("#set_additional_search_session_values helper was deprecated in Blacklight 4.x")
    end
    
    # we need to know if we are viewing the item as part of search results so we know whether to
    # include certain partials or not
    def adjust_for_results_view
      # deprecated in blacklight 4.x
      ActiveSupport::Deprecation.warn("#adjust_for_results_view helper was deprecated in Blacklight 4.x")
    end

    # extract the pagination info from the response object
    def pagination_info response
      h = {}

      [:current_page, :next_page, :prev_page, :total_pages,
       :limit_value, :offset_value, :total_count,
       :first_page?, :last_page?].each do |k|
        h[k] = response.send(k)
      end

      h
    end
    
    def validate_sms_params
      case
      when params[:to].blank?
        flash[:error] = I18n.t('blacklight.sms.errors.to.blank')
      when params[:carrier].blank?
        flash[:error] = I18n.t('blacklight.sms.errors.carrier.blank')
      when params[:to].gsub(/[^\d]/, '').length != 10
        flash[:error] = I18n.t('blacklight.sms.errors.to.invalid', :to => params[:to])
      when !sms_mappings.values.include?(params[:carrier])
        flash[:error] = I18n.t('blacklight.sms.errors.carrier.invalid')
      end

      flash[:error].blank?
    end

    def sms_mappings
      {'Virgin' => 'vmobl.com',
      'AT&T' => 'txt.att.net',
      'Verizon' => 'vtext.com',
      'Nextel' => 'messaging.nextel.com',
      'Sprint' => 'messaging.sprintpcs.com',
      'T Mobile' => 'tmomail.net',
      'Alltel' => 'message.alltel.com',
      'Cricket' => 'mms.mycricket.com'}
    end

    def validate_email_params
      case
      when params[:to].blank?
        flash[:error] = I18n.t('blacklight.email.errors.to.blank')
      when !params[:to].match(defined?(Devise) ? Devise.email_regexp : /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
        flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
      end

      flash[:error].blank?
    end

    # when a request for /catalog/BAD_SOLR_ID is made, this method is executed...
    def invalid_solr_id_error
      flash[:notice] = I18n.t('blacklight.search.errors.invalid_solr_id')
      params.delete(:id)
      index
      render "index", :status => 404
    end

    def blacklight_solr
      @solr ||=  RSolr.connect(blacklight_solr_config)
    end

    def blacklight_solr_config
      Blacklight.solr_config
    end
end
