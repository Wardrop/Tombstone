module Tombstone
  App.controller :reservation do
    
    get :new do
      @root_places = Place.with_child_count.filter(:parent_id => nil).order(:name).naked.all
      render 'reservation/new'
    end
    
    get :view, :with => :id do
      @reservation = Allocation.with_pk([params[:id], 'reservation'])
      if @reservation
        render 'reservation/view'
      else
        render 'reservation/not_found'
      end
    end

    post :new, :provides => :json do
      form_errors = Sequel::Model::Errors.new
      response = {success: false, nextUrl: nil, form_errors: form_errors}

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
            end
          end
        end

        if !params['place'].is_a?(Hash) || params['place'].reject { |v| v.empty? }.empty?
          form_errors.add(:place, "must be selected")
          raise Sequel::Rollback
        end
        
        place = Place.with_pk(params['place'][-1])
        if place.nil?
          form_errors.add(:place, "does not exist")
          raise Sequel::Rollback
        end

        reservation = Reservation.new.set({
          place: place,
          status: params[:status],
          location_description: params[:location_description],
          comments: params[:comments]
        })
        if reservation.valid?
          reservation.save
        else
          form_errors.merge!(reservation.errors)
          raise Sequel::Rollback
        end

        roles.each { |type, role| role.add_allocation(reservation) }
        response[:nextUrl] = url(:view, :id => reservation.id)
      }
      response[:success] = true if response[:form_errors].empty?
      response.to_json
    end

  end
end