# frozen_string_literal: true
class CatalogController < ApplicationController

  include BlacklightRangeLimit::ControllerOverride

  include Blacklight::Catalog
  include Blacklight::Marc::Catalog


  configure_blacklight do |config|
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      rows: 10,
      group: true,
      q: '*:*',
      'group.field': 'source',
      'group.ngroups': true,
      'group.limit': 10
    }

    # solr path which will be added to solr base url before the other solr params.
    #config.solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
      qt: 'document',
      fl: '*',
      rows: 1,
      q: '{!term f=id v=$id}'
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'title'
    config.index.display_type_field = 'stream_source_info'
    config.index.thumbnail_method = :render_thumbnail
    config.index.group = 'source'
    #config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr field configuration for document/show views
    #config.show.title_field = 'title_display'
    #config.show.display_type_field = 'format'
    #config.show.thumbnail_field = 'thumbnail_path_ss'
    config.show.thumbnail_method = :render_thumbnail
    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation (note: It is case sensitive when searching values)

    config.add_facet_field 'Location_t', label: 'Location', solr_params: { 'facet.mincount' => 1 }

    # config.add_facet_field 'Composer_Librettist_pivot_field', label: 'Collaborators', :pivot => ['Composer_t', 'Librettist_t']

    config.add_facet_field 'Date_int', label: 'Date', 
     range: {
       num_segments: 4,
       assumed_boundaries: [1600, 1999],
       maxlength: 4
     }

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'OperaTitle_t', label: 'Opera Title'
    config.add_index_field 'title_t', label: 'Book Title'
    config.add_index_field 'CallNumber_t', label: 'Call Number'
    config.add_index_field 'Composer_t', label: 'Composer'
    config.add_index_field 'Librettist_t', label: 'Librettist'
    config.add_index_field 'author_t', label: 'Author'
    config.add_index_field 'binder_t', label: 'Binder'
    config.add_index_field 'Date_t', label: 'Date'
    config.add_index_field 'binddate_t', label: 'Binding Date'
    config.add_index_field 'publication_t', label: 'Publication Information'
    config.add_index_field 'Location_t', label: 'Location', link_to_search: true

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'OperaTitle_t', label: 'Opera Title'
    config.add_show_field 'title_t', label: 'Book Title'
    config.add_show_field 'CallNumber_t', label: 'Call Number'
    config.add_show_field 'Composer_t', label: 'Composer'
    config.add_show_field 'Librettist_t', label: 'Librettist'
    config.add_show_field 'author_t', label: 'Author'
    config.add_show_field 'binder_t', label: 'Binder'
    config.add_show_field 'AddPages_t', label: 'Additional Pages'
    config.add_show_field 'Theatre_t', label: 'Theatre'
    config.add_show_field 'Dedication_t', label: 'Dedication'
    config.add_show_field 'CensorPass_t', label: 'Censor Pass'
    config.add_show_field 'catnotes_t', label: 'Cataloging Notes'
    config.add_show_field 'Printer_t', label: 'Printer'
    config.add_show_field 'Date_t', label: 'Date'
    config.add_show_field 'binddate_t', label: 'Binding Date'
    config.add_show_field 'Location_t', label: 'Published'
    config.add_show_field 'Reference_t', label: 'Reference'
    config.add_show_field 'Description_t', label: 'Description'
    config.add_show_field 'Ballet_t', label: 'Ballet'
    config.add_show_field 'Cast_t', label: 'Cast'
    config.add_show_field 'Responsibility_t', label: 'Responsibility'
    config.add_show_field 'keywords_t', label: 'Subjects'
    config.add_show_field 'hrcnotes_t', label: 'Local Notes'
    config.add_show_field 'nationality_t', label: 'Nationality'
    config.add_show_field 'descnotes_t', label: 'Description Notes'
    config.add_show_field 'binddesc_t', label: 'Binding Description'
    config.add_show_field 'biblio_t', label: 'Bibliography'
    config.add_show_field 'publication_t', label: 'Publication Information'
    config.add_show_field 'origArtDisplay_t', label: 'Original Artwork Bound In'
    config.add_show_field 'stream_name', label: 'URL'
    
    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', label: 'All Fields'


    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.


    config.add_search_field('creator') do |field|
      field.solr_parameters = {
        qf: '${Composer_t,Librettist_t,author_t}'
      }
    end
    config.add_search_field('title') do |field|
      field.solr_parameters = {
        qf: '${OperaTitle_t,title_t,dc_title}'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc', label: 'relevance'
    config.add_sort_field 'titleSorter asc', label: 'title'


    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'
    config.autocomplete_suggester = 'default'
  end
end
