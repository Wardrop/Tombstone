module Tombstone
  
  allocation = proc do
    controller = @_controller[0].to_s
    model_klass = Tombstone.const_get(controller.capitalize)
    
    get :view, :with => :id, :map => controller do
      @allocation = model_klass.with_pk(params[:id])
      if @allocation
        render "#{controller}/view"
      else
        halt 404, render("#{controller}/not_found")
      end
    end
    
    get :new, :map => controller do
      @root_places = Place.filter(:parent_id => nil).order(:name).naked.all
      @funeral_directors = FuneralDirector.all
      render "#{controller}/new"
    end
    
    get :new_from_reservation, :map => "#{controller}/:id/new" do
      @allocation = Reservation.with_pk(params[:id])
      if not Allocation.filter(:id => params[:id], :type => 'interment').empty?
        halt 404, render("error", :locals => {
          :title => 'Interment Already Exists',
          :message => "An interment for reservation ##{params[:id]} already exists."
        })
      elsif @allocation
        @places = @allocation.place.ancestors(0, true).reverse
        @funeral_directors = FuneralDirector.all
        prepare_form(render("#{controller}/new_from_reservation"), {selector: 'form', values: @allocation.values})
      else
        halt 404, render("error", :locals => {
          :title => 'Reservation Not Found',
          :message => "The reservation with ID ##{params[:id]} does not exist."
        })
      end
    end
    
    get :edit, :map => "#{controller}/:id/edit" do
      @allocation = model_klass.with_pk(params[:id])
      if @allocation
        @places = @allocation.place.ancestors(0, true).reverse
        @funeral_directors = FuneralDirector.all
        prepare_form(render("#{controller}/edit"), {selector: 'form', values: @allocation.values})
      else
        halt 404, render("#{controller}/not_found")
      end
    end

    post :index, :provides => :json do
      allocation = model_klass.new
      response = {success: false, form_errors: allocation.errors, redirectTo: nil}
      save_allocation(allocation, params) do
        place_id = (!params['place'].is_a?(Array) || params['place'].reject { |v| v.empty? }.empty?) ? nil : params['place'][-1]
        allocation.set_only_valid params.merge(
          place_id: place_id,
          funeral_director_id: params['funeral_director']
        )
      end
    
      if allocation.errors.empty?
        response.merge!(success: true, redirectTo: url(:"#{controller}_view", :id => allocation.id))
        flash[:banner] = ['success', "#{controller.capitalize} was created successfully."]
      end
      response.to_json
    end
    
    put :index, :with => :id, :provides => :json do
      allocation = model_klass.with_pk(params[:id])
      response = {success: false, form_errors: allocation.errors, redirectTo: nil}
      if allocation.nil?
        response[:form_errors] = "Could not amend #{controller} ##{params[:id]} as it does not exist."
      else
        model_klass.db.transaction do
          allocation.roles_dataset.delete
          allocation.remove_all_roles
          allocation.values.select { |k,v| model_klass.restricted_columns.push(:id, :type) }
          save_allocation(allocation, params) do
            allocation.set_only_valid params.merge(
              place_id: params['place'][-1],
              funeral_director_id: params['funeral_director']
            )
          end
        end
      end
      
      if allocation.errors.empty?
        response.merge!(success: true, redirectTo: url(:"#{controller}_view", :id => allocation.id))
        flash[:banner] = ['success', "#{controller.capitalize} was amended successfully."]
      end
      response.to_json
    end
    
    delete :index, :with => :id do
      allocation = model_klass.with_pk(params[:id])
      if allocation.nil?
        flash[:banner] = ["error", "Could not delete #{controller} ##{params[:id]} as it does not exist."]
      else
        begin
          model_klass.db.transaction do
            allocation.roles_dataset.delete
            allocation.remove_all_roles
            allocation.destroy
          end
          flash[:banner] = ["success", "#{controller.capitalize} was deleted successfully."]
        rescue => e
          flash[:banner] = ["error", "Error occured while deleting #{controller} ##{params[:id]}. The error was: \n#{e.message}"]
          redirect url(:"#{controller}_view", :id => params[:id])
        end
      end
      redirect url(:index)
    end
  end
  
  App.controller :reservation, &allocation
  App.controller :interment, &allocation
end