module Tombstone
  
  allocation = proc do
    controller = @_controller[0].to_s
    Allocation = Tombstone.const_get(controller.capitalize)
    
    get :view, :with => :id, :map => controller do
      @allocation = Allocation.with_pk(params[:id])
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
    
    get :edit, :map => "#{controller}/:id/edit" do
      @allocation = Allocation.with_pk(params[:id])
      @places = @allocation.place.ancestors(0, true).reverse
      @funeral_directors = FuneralDirector.all
      if @allocation
        prepare_form(render("#{controller}/edit"), {selector: 'form', values: @allocation.values})
      else
        halt 404, render("#{controller}/not_found")
      end
    end

    post :index, :provides => :json do
      allocation = Allocation.new
      response = {success: false, form_errors: allocation.errors, redirectTo: nil}
      save_allocation(allocation, params) do
        allocation.set_only_valid params.merge(
          place_id: params['place'][-1],
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
      allocation = Allocation.with_pk(params[:id])
      response = {success: false, form_errors: allocation.errors, redirectTo: nil}
      if allocation.nil?
        response[:form_errors] = "Could not amend #{controller} ##{params[:id]} as it does not exist."
      else
        Allocation.db.transaction do
          allocation.roles.each { |r| r.destroy }
          allocation.remove_all_roles
          allocation.values.select { |k,v| Allocation.restricted_columns.push(:id, :type) }
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
        flash[:banner] = ['success', "#{controller.captialize} was amended successfully."]
      end
      response.to_json
    end
    
    delete :index, :with => :id do
      allocation = Allocation.with_pk(params[:id])
      if allocation.nil?
        flash[:banner] = ["error", "Could not delete #{controller} ##{params[:id]} as it does not exist."]
      else
        begin
          delete_allocation(allocation)
          flash[:banner] = ["success", "#{controller.captialize} was deleted successfully."]
        rescue => e
          flash[:banner] = ["error", "Error occured while deleting #{controller} ##{params[:id]}. The error was: \n#{e.message}"]
          redirect url(:"#{controller}_view", :with => params[:id])
        end
      end
      redirect url(:index)
    end
    
  end
  
  App.controller :reservation, &allocation
  App.controller :interment, &allocation
end