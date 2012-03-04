module Tombstone
  App.controller :find do
    
    get :index do
      @records = []
      unless params['search'].blank? && params['type'].blank?
        search_class = (params['type'] == 'allocations') ? AllocationSearch : PersonSearch
        conditions = parse_search_string(params['search'], search_class.searchable.keys)
        @records = search_class.new.query(conditions).all
      end
      prepare_form(render('find/index'), {selector: '#search_defintion', values: params})
    end
    
  end
end