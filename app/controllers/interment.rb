# module Tombstone
#   App.controller :interment do
#     base = @_controller[0].to_s
# 
#     get :view, :with => :id, :map => base do
#       @interment = Interment.with_pk(params[:id])
#       if @interment
#         render 'interment/view'
#       else
#         halt 404, render('interment/not_found')
#       end
#     end
#     
#     get :new, :map => base do
#       @root_places = Place.filter(:parent_id => nil).order(:name).naked.all
#       @funeral_directors = FuneralDirector.all
#       render 'interment/new'
#     end
#     
#     get :edit, :map => "#{base}/:id/edit" do
#       @interment = Interment.with_pk(params[:id])
#       @places = @interment.place.ancestors(0, true).reverse
#       @funeral_directors = FuneralDirector.all
#       if @interment
#         prepare_form(render('interment/edit'), {selector: 'form', values: @interment.values})
#       else
#         halt 404, render('interment/not_found')
#       end
#     end
#     
#     post :index, :provides => :json do
#       interment = Interment.new
#       response = {success: false, form_errors: interment.errors, redirectTo: nil}
#       save_allocation(interment, params) do
#         interment.set_only_valid params.merge(
#           place_id: params['place'][-1],
#           funeral_director_id: params['funeral_director']
#         )
#       end
#     
#       if interment.errors.empty?
#         response.merge!(success: true, redirectTo: url(:interment_view, :id => interment.id))
#         flash[:banner] = ['success', "Interment created successfully"]
#       end
#       response.to_json
#     end
#     
#     put :index, :with => :id, :provides => :json do
#       interment = Interment.with_pk(params[:id])
#       response = {success: false, form_errors: interment.errors, redirectTo: nil}
#       if interment.nil?
#         response[:form_errors] = "Could not amend interment ##{params[:id]} as it does not exist."
#       else
#         Interment.db.transaction do
#           interment.roles.each { |r| r.destroy }
#           interment.remove_all_roles
#           interment.values.select { |k,v| Interment.restricted_columns.push(:id, :type) }
#           save_allocation(interment, params) do
#             interment.set_only_valid params.merge(
#               place_id: params['place'][-1],
#               funeral_director_id: params['funeral_director']
#             )
#           end
#         end
#       end
#       
#       if interment.errors.empty?
#         response.merge!(success: true, redirectTo: url(:interment_view, :id => interment.id))
#         flash[:banner] = ['success', "Interment amended successfully"]
#       end
#       response.to_json
#     end
#     
#     delete :index, :with => :id do
#       interment = Interment.with_pk(params[:id])
#       if interment.nil?
#         flash[:banner] = ["error", "Could not delete interment ##{params[:id]} as it does not exist."]
#       else
#         begin
#           delete_allocation(interment)
#           flash[:banner] = ["success", "Interment was deleted successfully."]
#         rescue => e
#           flash[:banner] = ["error", "Error occured while deleting interment ##{params[:id]}. The error was: \n#{e.message}"]
#           redirect url(:interment_view, :with => params[:id])
#         end
#       end
#       redirect url(:index)
#     end
#     
#   end 
# end