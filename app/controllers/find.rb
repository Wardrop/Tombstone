require 'csv'

module Tombstone
  Root.controller '/find', conditions: {logged_in: true} do
    get '/' do
      @records = []
      @rejected_terms = []
      @search_class = nil
      terms = []
      record_limit = request.GET['record_limit'] || CONFIG[:search_record_limit]
      unless request.GET['search'].blank? && request.GET['type'].blank?
        @search_class = case request.GET['type']
          when 'people'
            PersonSearch
          when 'places'
            PlaceSearch
          else
            AllocationSearch
          end

        terms = parse_search_string(request.GET['search'])
        original_terms = terms.clone
        order = (request.GET['order_by']) ? [[request.GET['order_by'], request.GET['order_dir']]] : []
        @records = @search_class.new.query(terms, [[request.GET['order_by'], request.GET['order_dir']]], record_limit).all
        @rejected_terms = original_terms.reject { |v| terms.any? { |t| t[:field] == v[:field] } }
      end

      if request.GET['export']
        export_csv
      else
        prepare_form(render(:'find/index'), {
          selector: '#search_defintion',
          values: request.GET.merge({
            'search' => terms.map{ |v| "#{v[:field]}#{v[:operator]}#{v[:value]}"}.join(' ').strip
          })
        })
      end
    end

    def export_csv
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
      response['Content-Disposition'] = "attachment; filename=Tombstone Search Export #{Time.now.to_i}.csv"
      response['Content-Type'] = 'text/csv'
      output
    end

    # Takes a string in a format similar to "some term field1:some value field2:another value", and returns an array of
    # terms, consisting of the field name, operator and value. Any text before the first term is returned as the first
    # return value.
    def parse_search_string(str)
      str ||= ''
      operators = [':', '>', '<']
      indices = []
      loop do
        offset = (indices.last) ? str.index(Regexp.union(operators), indices.last) + 1 : 0
        index = str.index(/(?<=^| )[a-zA-Z0-9_]+#{Regexp.union operators}/, offset)
        (index) ? indices << index : break
      end
      terms = []
      indices.each_index do |i|
        field, operator, value = str[Range.new(indices[i], (indices[i+1] || 0) - 1)].strip.partition(Regexp.union operators)
        value = value.strip
        terms << {field: field.to_sym, operator: operator, value: value.strip} unless value.empty?
      end
      general_term = str[Range.new(0, indices.first || str.length, true)].strip.gsub(/ +/, ' ')
      terms.unshift(field: :all, operator: ':', value: general_term) unless general_term.empty?
      terms
    end

  end
end
