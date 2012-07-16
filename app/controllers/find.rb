module Tombstone
  App.controller :find do
    
    get :index do
      @records = []
      @rejected_terms = []
      @search_class = nil
      terms = []
      unless params['search'].blank? && params['type'].blank?
        @search_class = case params['type']
          when 'people'
            PersonSearch
          when 'places'
            PlaceSearch
          else
            AllocationSearch
          end
        
        terms = parse_search_string(params['search'])
        original_terms = terms.clone
        order = (params['order_by']) ? [[params['order_by'], params['order_dir']]] : []
        @records = @search_class.new.query(terms, [[params['order_by'], params['order_dir']]], settings.config[:search_record_limit]).all
        @rejected_terms = original_terms.reject { |v| terms.any? { |t| t[:field] == v[:field] } }
      end
      prepare_form(render('find/index'), {
        selector: '#search_defintion',
        values: params.merge({
          'search' => terms.map{ |v| "#{v[:field]}#{v[:operator]}#{v[:value]}"}.join(' ').strip
        })
      })
    end
    
  end
end