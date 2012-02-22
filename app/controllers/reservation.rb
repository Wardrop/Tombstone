module Tombstone
  App.controller :reservation do
    
    get :index do
      redirect to(:find)
    end
    
    get :view, :with => :id do
      @reservation = Reservation.with_pk(params[:id])
      if @reservation
        render 'reservation/view'
      else
        halt 404, render('reservation/not_found')
      end
    end
    
    get :new do
      @root_places = Place.filter(:parent_id => nil).order(:name).naked.all
      render 'reservation/new'
    end
    
    get :edit, :with => :id do
      @reservation = Reservation.with_pk(params[:id])
      @places = @reservation.place.ancestors(0, true).reverse
      if @reservation
        prepare_form(render('reservation/edit'), {selector: 'form', values: @reservation.values})
      else
        halt 404, render('reservation/not_found')
      end
    end

    post :new, :provides => :json do
      params.symbolize_keys!
      form_errors = Sequel::Model::Errors.new
      response = {success: false, form_errors: form_errors, nextUrl: nil}

      Reservation.db.transaction {
        roles = {}
        [:reservee, :applicant, :next_of_kin].each do |role_name|
          role_data = params[role_name.to_s]
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
        
        reservation = Reservation.new(Reservation.filter_by_columns(params).merge(
          place_id: params[:place][-1]
        ))
        if reservation.valid?
          reservation.save
        else
          form_errors.merge!(reservation.errors)
          raise Sequel::Rollback
        end

        roles.each { |type, role| role.add_allocation(reservation) }
      }
      if response[:form_errors].empty?
        response[:success] = true 
        response[:nextUrl] = url(:reservation_view, :id => reservation.id)
        flash[:banner] = ['success', "Reservation created successfully"]
      end
      response.to_json
    end
    
    post :edit, :with => :id, :provides => :json do
      @reservation = Reservation.with_pk(params[:id])
      return "Reservation with ##{params[:id]} does not exist.".to_json
      
      Reservation.db.transaction do
        @reservation.roles.each { |r| r.destroy }
        @reservation.remove_all_roles
        @reservation.values.select { |k,v| Reservation.restricted_columns.push(:id, :type) }
        
        saveAllocation(@reservation, params)
      end
    end
    
  end
end