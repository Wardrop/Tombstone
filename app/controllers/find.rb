module Tombstone
  App.controller :find do
    
    get :index do
      @records = []
      unless params['search'].blank? && params['type'].blank?
        search_class = (params['type'] == 'allocations') ? AllocationSearch : PersonSearch
        general, specific = parse_search_string(params['search'], search_class.searchable.keys)
        conditions = (general.blank?) ? {'all' => general}.merge(specific) : specific 
        @records = search_class.new.query(conditions).all
      end
      prepare_form(render('find/index'), {
        selector: '#search_defintion',
        values: params.merge({
          'search' => conditions.map{|f,v| "#{f}:#{v}"}.join(' ').strip
        })
      })
    end
    
  end
end