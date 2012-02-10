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
      response = {success: false, form_errors: {}}
      response[:form_errors]['place'] = "must be selected" if params['place'].reject { |v| v.empty? }.empty?
      
      Allocation.db.transaction {
        roles = {}
        ['reservee', 'applicant', 'next_of_kin'].each do |name|
          data = params[name]
          if data.nil? || !data.is_a?(Hash)
            response[:form_errors][name] = "must be added"
          else
            if data['person']['id']
              person = Person[data['person']['id']]
              if person.nil?
                response[:form_errors][name] = "does not exist"
                raise Sequel::Rollback
              end
            else
              person = Person.new.set(data['person'])
              if person.valid?
                person.save
              else
                response[:form_errors][name] = person.errors
                raise Sequel::Rollback
              end
            end

            if data['residential_contact']['id']
              res_contact = Contact[data['residential_contact']['id']]
              if res_contact.nil?
                response[:form_errors][name] = "for the selected '#{name.demodulize.titlecase}' does not exist"
                raise Sequel::Rollback
              end
            else
              res_contact = Contact.new.set(data['residential_contact'])
              if res_contact.valid?
                res_contact.save
              else
                response[:form_errors][name] = res_contact.errors
                raise Sequel::Rollback
              end
            end

            role = Role.new.set({type: name, person: person, residential_contact: res_contact})
            if role.valid?
              role.save
              roles[name] = role
            else
              response[:form_errors][name] = role.errors
              raise Sequel::Rollback
            end
          end
          
        end

        place = Place[params['place'][-1]]
        if place.nil?
          response[:form_errors]['place'] = "does not exist"
          raise Sequel::Rollback
        elsif place.allocations.empty? == false && place.allocations.reject{ |v| v.type != 'reservation' }.empty? == false
          response[:form_errors]['place'] = "is already associated with another reservation"
          raise Sequel::Rollback
        end

        allocation = Allocation.new.set({type: 'reservation', place: place})
        if allocation.valid?
          allocation.save
        else
          response[:form_errors].merge!(allocation.errors)
          raise Sequel::Rollback
        end

        roles.each do |type, role|
          role.add_allocation(allocation)
        end

        response[:success] = true
      }

      response.to_json
    end
    
  end
end