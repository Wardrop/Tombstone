module Tombstone
  App.controller :interment do
    
    get :index do
      redirect to(:find)
    end
    
    get :view, :with => :id do
      @interment = Interment.with_pk(params[:id])
      if @interment
        render 'interment/view'
      else
        halt 404, render('interment/not_found')
      end
    end
    
    get :new do
      @root_places = Place.filter(:parent_id => nil).order(:name).naked.all
      @funeral_directors = FuneralDirector.all
      render 'interment/new'
    end
    
    post :new, :provides => :json do
      params.symbolize_keys!
      form_errors = Sequel::Model::Errors.new
      response = {success: false, form_errors: form_errors, nextUrl: nil}

      Interment.db.transaction {
        roles = {}
        [:deceased, :applicant, :next_of_kin].each do |role_name|
          role_data = params[role_name]
          if role_data.nil? || !role_data.is_a?(Hash)
            form_errors.add(role_name, "must be added")
          else
            role_errors = Sequel::Model::Errors.new
            begin
              roles[role_name] = Role.create_from(role_data, role_errors)
            rescue Sequel::Rollback => e
              form_errors.add(role_name, role_errors)
              raise
            end
          end
        end

        if !params[:place].is_a?(Array) || params[:place].reject { |v| v.empty? }.empty?
          form_errors.add(:place, "must be selected")
          raise Sequel::Rollback
        end
        
        interment = Interment.new(Interment.filter_by_columns(params).merge(
          place_id: params[:place][-1],
          funeral_director_id: params[:funeral_director]
        ))
        if interment.valid?
          interment.save
        else
          form_errors.merge!(interment.errors)
          raise Sequel::Rollback
        end

        roles.each { |type, role| role.add_allocation(interment) }
        response[:nextUrl] = url(:interment_view, :id => interment.id)
      }
      if response[:form_errors].empty?
        response[:success] = true 
        flash[:banner] = ['success', "Interment created successfully"]
      end
      response.to_json
    end
  end
    
end