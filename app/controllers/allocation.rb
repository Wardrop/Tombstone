module Tombstone
  
  allocation = proc do
    controller = @_controller[0].to_s
    model_class = Tombstone.const_get(controller.capitalize)
    
    get :view, :with => :id, :map => controller do
      @allocation = model_class.with_pk(params[:id].to_i)
      if @allocation
        render "#{controller}/view"
      else
        halt 404, render("#{controller}/not_found")
      end
    end
    
    get :edit, :map => "#{controller}/:id/edit" do
      reset_file_changes
      @allocation = model_class.with_pk(params[:id].to_i)
      if @allocation
        @funeral_directors = FuneralDirector.all
        prepare_form(render("#{controller}/edit"), {selector: 'form', values: @allocation.values})
      else
        halt 404, render("#{controller}/not_found")
      end
    end

    post :index, :provides => :json do
      allocation = model_class.new
      response = {errors: allocation.errors, warnings: [], redirectTo: nil}
      place_id = (!params['place'].is_a?(Array) || params['place'].reject { |v| v.empty? }.empty?) ? nil : params['place'][-1]
      save_allocation(allocation, params)
      if allocation.errors.empty?
        if allocation.warnings.empty?
          response[:redirectTo] = url(:"#{controller}_view", :id => allocation.id)
          flash[:banner] = ['success', "#{controller.capitalize} was created successfully. To create a new reservation, <a href='#{url '/reservation'}'>click here</a>"]
        else
          response[:warnings] = allocation.warnings
        end
      end
      json_response(response)
    end

    put :index, :with => :id, :provides => :json do
      allocation = model_class.with_pk(params[:id].to_i)
      if @user.role == 'operator' && allocation.status == 'approved'
        params['status'] = 'pending'
      end
      response = {errors: allocation.errors, warnings: [], redirectTo: nil}
      if allocation.nil?
        response[:errors] = "Could not amend #{controller} ##{params[:id]} as it does not exist."
      else
        model_class.db.transaction do
          allocation.roles_dataset.delete
          allocation.remove_all_roles
          allocation.transactions_dataset.delete
          # allocation.values.select { |k,v| model_class.restricted_columns.push(:id, :type) }
          save_allocation(allocation, params)
        end
      end
      
      if allocation.errors.empty?
        if allocation.warnings.empty?
          response[:redirectTo] = url(:"#{controller}_view", :id => allocation.id)
          flash[:banner] = ['success', "#{controller.capitalize} was amended successfully."]
        else
          response[:warnings] = allocation.warnings
        end
      end
      json_response(response)
    end
    
    put :status, :map => "#{controller}/:id/status", :provides => :json do
      allocation = model_class.with_pk(params[:id].to_i)
      response = {errors: allocation.errors, redirectTo: url("#{controller}_view".to_sym, :id => params[:id])}
      if allocation.nil?
        response[:errors] = "Could not edit status of #{controller} ##{params[:id]} as it does not exist."
      else
        allocation.set({status: params['status']})
        if allocation.valid?
          allocation.save
          flash[:banner] = ['success', "Status of #{controller.capitalize} ##{params[:id]} was updated successfully."]
        end
      end
      json_response(response)
    end
    
    delete :index, :with => :id do
      allocation = model_class.with_pk(params[:id].to_i)
      if allocation.nil?
        flash[:banner] = ["error", "Could not delete #{controller} ##{params[:id]} as it does not exist."]
      else
        begin
          if allocation.status == 'provisional'
            model_class.db.transaction do
              allocation.transactions_dataset.delete
              allocation.roles_dataset.delete
              allocation.remove_all_roles
              allocation.destroy
            end
          else
            allocation.set(status: 'deleted').save(:status)
          end
          flash[:banner] = ["success", "#{controller.capitalize} was deleted successfully."]
        rescue => e
          p e
          flash[:banner] = ["error", "Error occured while deleting #{controller} ##{params[:id]}. The error was: \n#{e.message}"]
        end
      end
      
      if allocation.exists?
        redirect url(:"#{controller}_view", :id => allocation.id)
      else
        redirect url(:index)
      end
    end
  end
  
  App.controller :reservation, &allocation
  App.controller :reservation do
    get :new, :map => 'reservation' do
      @allocation = Reservation.new
      render "reservation/new"
    end
  end
  
  App.controller :interment, &allocation
  App.controller :interment do
    get :new, :map => 'interment' do
      @allocation = Interment.new
      @allocation.set_valid_only(params)
      @funeral_directors = FuneralDirector.all
      if @allocation.place_id
        if not @allocation.place
          halt 500, render("error", :locals => {
            :title => 'Place Does Not Exist',
            :message => "The specified place does not exist."
          })
        elsif not @allocation.place.allows_interment?
          halt 500, render("error", :locals => {
            :title => 'Interment Not Allowed',
            :message => "The specified place cannot be used.
                         The place may be unavailable, invalid, or it exceeds the maximum number of allowed interments."
          })
        end
      end
      prepare_form(render("interment/new"), {selector: 'form', values: @allocation.values})
    end
    
    get :new_from_reservation, :map => "interment/from_reservation/:id" do
      @allocation = Reservation.with_pk(params[:id].to_i)
      if !@allocation
        halt 404, render("error", :locals => {
          :title => 'Reservation Not Found',
          :message => "The reservation with ID ##{params[:id]} does not exist."
        })
      elsif not @allocation.interments.empty?
        halt 500, render("error", :locals => {
          :title => 'Interment Already Exists',
          :message => "An interment for reservation ##{params[:id]} already exists."
        })
      else
        @allocation.roles.each { |r| r.type = 'deceased' if r.type == 'reservee' }
        @funeral_directors = FuneralDirector.all
        prepare_form(render("interment/new"), {selector: 'form', values: @allocation.values})
      end
    end
  end
end