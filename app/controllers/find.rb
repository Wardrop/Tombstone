module Tombstone
  App.controller :find do
    
    get :index do
      @searchable = {
        dob: "[DATE_OF_BIRTH]",
        name: ["(' '+[TITLE]+' '+[FIRST_NAME]+' '+[SURNAME])", proc { |f| "% #{f}" }],
        email: "[EMAIL]",
        address: ["(' '+[STREET_ADDRESS]+', '+[TOWN]+' '+[STATE]+' '+CAST([POSTAL_CODE] as nvarchar))", proc { |f| "% #{f}" }]
      }
      @sortable = {
        created_at: 'Date created',
        modified_at: 'Date modified',
        first_name: 'First Name',
        last_name: 'Last Name'
      }
      if params.empty?
        @records = Allocation.filter.all
      else
        return Allocation.db["SELECT * FROM role"].naked.all.to_s
      end
      render 'find/index'
    end
    
  end
end