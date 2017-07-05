module Tombstone
  class AllocationController < Controller
    def self.inherited(klass)
      klass.mappings.push(*mappings)
    end

    get '/:id' do |id|
      @allocation = model.with_pk(id.to_i)
      if @allocation
        render :view
      else
        halt 404, render(:not_found)
      end
    end

    get '/*/edit' do |id|
      @allocation = model.with_pk(id.to_i)
      if @allocation
        @funeral_directors = FuneralDirector.all
        prepare_form(render(:edit), {selector: 'form', values: @allocation.values})
      else
        halt 404, render(:not_found)
      end
    end

    post '/', media_type: 'application/json' do
      allocation = model.new
      response = {errors: allocation.errors, warnings: [], redirectTo: nil}
      place_id = (!request.POST['place'].is_a?(Array) || request.POST['place'].reject { |v| v.empty? }.empty?) ? nil : request.POST['place'][-1]
      save_allocation(allocation, request.POST)
      if allocation.errors.empty?
        if allocation.warnings.empty?
          response[:redirectTo] = "#{request.path}/#{allocation.id}"
          flash[:banner] = ['success', "#{type.capitalize} was created successfully. To create a new reservation, <a href='#{absolute '/reservation'}'>click here</a>"]
        else
          response[:warnings] = allocation.warnings
        end
      end
      json_response(response)
    end

    put '/*', media_type: 'application/json' do |id|
      allocation = model.with_pk(id.to_i)
      if env['tombstone.user'].role == 'operator' && allocation.status == 'approved'
        request.POST['status'] = 'pending'
      end
      response = {errors: allocation.errors, warnings: [], redirectTo: nil}
      if allocation.nil?
        response[:errors] = "Could not amend #{type} ##{id} as it does not exist."
      else
        model.db.transaction do
          allocation.roles_dataset.delete
          allocation.remove_all_roles
          allocation.transactions_dataset.delete
          # allocation.values.select { |k,v| model.restricted_columns.push(:id, :type) }
          save_allocation(allocation, request.POST)
        end
      end

      if allocation.errors.empty?
        if allocation.warnings.empty?
          response[:redirectTo] = "../#{allocation.id}"
          flash[:banner] = ['success', "#{type.capitalize} was amended successfully."]
        else
          response[:warnings] = allocation.warnings
        end
      end
      json_response(response)
    end

    put '/*/status', media_type: 'application/json' do |id|
      allocation = model.with_pk(id.to_i)
      response = {errors: allocation.errors, redirectTo: "./#{id}"}
      if allocation.nil?
        response[:errors] = "Could not edit status of #{type} ##{id} as it does not exist."
      elsif allocation.status == request.POST['status']
        flash[:banner] = ['success', "Status of #{type.capitalize} ##{id} was updated successfully."]
      else
        allocation.set({status: request.POST['status']})
        if request.POST['status'] == 'deleted' || allocation.valid?
          allocation.save(validate: false)
          Notifiers::ChangedStatus.new(allocation).send
          flash[:banner] = ['success', "Status of #{type.capitalize} ##{id} was updated successfully."]
        end
      end
      json_response(response)
    end

    delete '/*' do |id|
      allocation = model.with_pk(id.to_i)
      if allocation.nil?
        flash[:banner] = ["error", "Could not delete #{type} ##{id} as it does not exist."]
      else
        begin
          if ['provisional', 'deleted'].include? allocation.status
            model.db.transaction do
              allocation.legacy_fields_dataset.delete
              allocation.transactions_dataset.delete
              allocation.roles_dataset.delete
              allocation.remove_all_roles
              allocation.destroy
            end
          else
            allocation.set(status: 'deleted').save(columns: [:status])
            Notifiers::ChangedStatus.new(allocation).send
          end
          flash[:banner] = ["success", "#{type.capitalize} was deleted successfully."]
        rescue => e
          flash[:banner] = ["error", "Error occured while deleting #{type} ##{id}. The error was: \n#{e.message}"]
        end
      end

      if allocation.exists?
        redirect "./#{allocation.id}"
      else
        redirect "./"
      end
    end

    # Takes an optional block which is yielded directly before the allocation is validated and saved.
    # Block is given the allocation object and data hash as arguments.
    def save_allocation(allocation, data)
      allocation.db.transaction do
        # Remap form values.
        values = Hash[ request.POST.map { |k,v|
          case k
          when 'place'
            v = (!request.POST['place'].is_a?(Array) || request.POST['place'].reject { |v| v.empty? }.empty?) ? nil : request.POST['place'][-1]
            k = :place_id
          end
          [k, v]
        } ]

        allocation.set_valid_only(values)
        allocation.save(validate: false)

        roles_data = data.select { |k,v| allocation.class.valid_roles.include?(k) && !v.nil? && Hash === v }
        roles_data.reject{ |k,v| v['use'] }.each do |key, role_data|
          role_errors = Sequel::Model::Errors.new
          begin
            if role_data['id']
              role = Role.with_pk(role_data['id'])
              if role
                role_errors = role.errors
                role.set_valid_only(role_data).save
              else
                role_errors.add(:id, "does not exist")
              end
            else
              allocation.add_role(Role.create_from(role_data, role_errors))
            end
          rescue Sequel::Rollback => e
            allocation.errors.add(key.to_sym, role_errors)
          end
        end
        allocation.roles.each do |role|
          roles = roles_data.values.select{ |v| v['use'] ==  role.type }
          roles.each do |v|
            r = Role.new.set_valid_only(role.values.merge(type: v['type']))
            if r.valid?
              r.save
              allocation.add_role(r)
            else
              allocation.errors.add(v['type'].to_sym, r.errors)
              raise Sequel::Rollback
            end
          end
        end

        if request.POST['transactions'].is_a? Array
          request.POST['transactions'].reject{ |v| v.blank? }.each do |trans|
            trans = Transaction.new(allocation_id: allocation.id, receipt_no: trans)
            if trans.valid?
              trans.save
            else
              allocation.errors.add(:transaction, trans.errors)
              raise Sequel::Rollback
            end
          end
        end

        if allocation.status == 'provisional'
          allocation.valid?
          allocation.errors.select!{ |k,v| k == :place }
          if allocation.errors.empty?
            if !request.GET.has_key?('confirm') && allocation.has_warnings?
              raise Sequel::Rollback
            end
          else
            raise Sequel::Rollback
          end
        elsif allocation.errors.empty? && allocation.valid?
          if !request.GET.has_key?('confirm') && allocation.has_warnings?
            raise Sequel::Rollback
          end
        else
          raise Sequel::Rollback
        end

        if allocation.new?
          if allocation.status != 'provisonal'
            Notifiers::NewInterment.new(allocation).send
          end
        else
          if allocation.previous_changes.nil? || (allocation.previous_changes[:status] && allocation.previous_changes[:status].first == 'provisional' && allocation.status != 'deleted')
            Notifiers::NewInterment.new(allocation).send
          else
            if allocation.previous_changes[:status]
              Notifiers::ChangedStatus.new(allocation).send
            end
            if allocation.previous_changes[:interment_date]
              if allocation.previous_changes[:interment_date].first != allocation.interment_date
                Notifiers::ChangedIntermentDate.new(allocation).send
              end
            end
          end
        end
      end
    end
  end

  Root.controller '/interment', AllocationController, conditions: {logged_in: true} do
    def model; Interment; end
    def type; 'interment'; end
    render_defaults[:dir] = File.join(render_defaults[:dir], 'interment')

    get '/' do
      @allocation = model.new
      @allocation.set_valid_only(request.GET)
      @funeral_directors = FuneralDirector.all
      if @allocation.place_id
        if not @allocation.place
          halt 500, render(:'../error', :locals => {
            :title => 'Place Does Not Exist',
            :message => "The specified place does not exist."
          })
        elsif not @allocation.place.allows_interment?
          halt 500, render(:'../error', :locals => {
            :title => 'Interment Not Allowed',
            :message => "The specified place cannot be used.
                         The place may be unavailable, invalid, or it exceeds the maximum number of allowed interments."
          })
        end
      end
      prepare_form(render(:new), {selector: 'form', values: @allocation.values})
    end

    get '/from_reservation/*' do |id|
      @allocation = Reservation.with_pk(id.to_i)
      if !@allocation
        halt 404, render(:'../error', :locals => {
          :title => 'Reservation Not Found',
          :message => "The reservation with ID ##{id} does not exist."
        })
      elsif not @allocation.interments.empty?
        halt 500, render(:'../error', :locals => {
          :title => 'Interment Already Exists',
          :message => "An interment for reservation ##{id} already exists."
        })
      else
        @allocation.roles.each { |r| r.type = 'deceased' if r.type == 'reservee' }
        @funeral_directors = FuneralDirector.all
        prepare_form(render(:new), {selector: 'form', values: @allocation.values})
      end
    end
  end

  Root.controller '/reservation', AllocationController, conditions: {logged_in: true} do
    def model; Reservation; end
    def type; 'reservation'; end
    render_defaults[:dir] = File.join(render_defaults[:dir], 'reservation')

    get '/' do
      @allocation = Reservation.new
      render :new
    end
  end
end
