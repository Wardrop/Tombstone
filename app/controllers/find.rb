require 'csv'

module Tombstone
  App.controller :find do
    
    get :index do
      @records = []
      @rejected_terms = []
      @search_class = nil
      terms = []
      record_limit = params['record_limit'] || settings.config[:search_record_limit]
      unless params['search'].blank? && params['type'].blank?
        @search_class = case params['type']
          when 'people'
            PersonSearch
          when 'places'
            PlaceSearch
          else
            AllocationSearch
          end
        
        terms = parse_search_string(params['search'])
        original_terms = terms.clone
        order = (params['order_by']) ? [[params['order_by'], params['order_dir']]] : []
        @records = @search_class.new.query(terms, [[params['order_by'], params['order_dir']]], record_limit).all
        @rejected_terms = original_terms.reject { |v| terms.any? { |t| t[:field] == v[:field] } }
      end
      
      if params['export']
        formatted_records = []
        @records.each do |record|
          main_role = record.role_by_type('deceased') || record.role_by_type('reservee')
          applicant = record.role_by_type('applicant') 
          next_of_kin = record.role_by_type('next_of_kin')
          formatted_records << {
            type: record.type.demodulize.titleize,
            :'reservee/deceased' => print(nil) { "#{main_role.person.title} #{main_role.person.given_name} #{main_role.person.middle_name} #{main_role.person.surname}" },
            place: print(nil) { record.place.full_name },
            status: print(nil) { record.status.demodulize.titleize },
            applicant: print(nil) { "#{applicant.person.title} #{applicant.person.given_name} #{applicant.person.surname}" },
            next_of_kin: print(nil) { "#{next_of_kin.person.title} #{next_of_kin.person.given_name} #{next_of_kin.person.surname}" },
            created: print('unknown') { "#{record.created_at.strftime('%d/%m/%Y %l:%M%P')} by #{record.created_by}" },
            last_modified: print('never') { "#{record.modified_at.strftime('%d/%m/%Y %l:%M%P')} by #{record.modified_by}" },
            interment_type: print(nil) { record.interment_type.demodulize.titleize },
            advice_received_date: print(nil) { record.advice_received_date },
            interment_date: print(nil) { record.interment_date.strftime('%d/%m/%Y %l:%M%P')}
          }
        end
        
        output = ''
        unless formatted_records.empty?
          csv = CSV.new(output)
          csv << formatted_records[0].keys
          formatted_records.each { |record| csv << record.values }
        end
        response.headers.merge!(
          'Content-Disposition' => 'attachment; filename=tombstone_search_export.csv',
          'Content-Type' => 'text/csv')
        output
      else
        prepare_form(render('find/index'), {
          selector: '#search_defintion',
          values: params.merge({
            'search' => terms.map{ |v| "#{v[:field]}#{v[:operator]}#{v[:value]}"}.join(' ').strip
          })
        })
      end
    end
    
  end
end