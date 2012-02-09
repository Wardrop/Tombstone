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

    post :new, :provides => 'json' do
      content_type :json
      response = {success: false, form_errors: {}}
      response[:form_errors]['reservee'] = "Reservee must be added to reservation." unless params['reservee'].is_a? Hash
      #response[:form_errors]['next_of_kin'] = "Next of Kin must be added to reservation." unless params['next_of_kin'].is_a? Hash
      #response[:form_errors]['applicant'] = "Applicant must be added to reservation." unless params['applicant'].is_a? Hash
      response[:form_errors]['place'] = "A place must be selected." unless params['place']

      if response[:form_errors].empty?
        Allocation.db.transaction do

          roles = {}
          params.select { |k,v| ['reservee', 'applicant'].include? k}.each do |name, data|
            if data['person']['id']
              person = Person[data['person']['id']]
              if person.nil?
                response[:form_errors][name] = "The selected '#{name.capitalize}' does not exist."
                raise Sequel::Rollback
              end
            else
              person = Person.new.set(data['person'])
              if person.is_valid?
                person.save
              else
                response[:form_errors][name] = person.errors
                raise Sequel::Rollback
              end
            end

            if data['residential_contact']['id']
              res_contact = Contact[data['residential_contact']['id']]
              if res_contact.nil?
                response[:form_errors][name] = "The selected contact for the selected '#{name.capitalize}' does not exist."
                raise Sequel::Rollback
              end
            else
              res_contact = Contact.new.set(data['residential_contact'])
              if res_contact.is_valid?
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

          place = Place[params['place']]
          if place.nil?
            response[:form_errors]['place'] = "The selected place does not exist."
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
        end
      end

      response.to_json
    end
    
  end
end