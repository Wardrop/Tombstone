module Tombstone
  App.helpers do

    def include_script_views(*names)
      names.each do |name|
        @document[:scripts] << "views/#{name}.js"
        content_for :head do
          File.read File.join(settings.views, "script_templates/#{name}.html")
        end
      end
    end
    
    def build_breadcrumb(segments = nil)
      if segments.nil?
        route_name = route.named.to_s.sub(Regexp.new(/^#{route.controller}_/), '')
        segments = []
        segments << ['', "/"]
        segments << [
          route.controller.demodulize.titleize,
          request.path_info.slice(/^\/#{route.controller}(.*(?=\/#{route_name})|.*)/)
        ]
        segments << [route_name.demodulize.titleize, request.path_info] unless route_name == 'index'
      end
      segments.map { |title, uri|
        "<a href='#{url uri}' class='breadcrumb #{(title.empty?) ? 'home' : ''}'>#{title}</a>"
      }.join('<span class="breadcrumb div">/</span>')
    end
    
    # Renders field data, handling nil values and formatting of objects such as Dates.
    # Can take an optional block which has the advantage of being error-handled (e.g. calling a method on a nil object).
    def print(fallback = '<small>none</small>', &block)
      value = block.call rescue nil
      if value.blank?
        fallback
      else
        case value
        when Time
          ((value.hour + value.min + value.sec) > 0) ? value.strftime('%d/%m/%Y %l:%M%P') : value.strftime('%d/%m/%Y')
        else
          value
        end
      end
    end
    
    # Takes a plain xml/xhtml string, an array of field names indicating which fields have errors, and an array of
    # field/value pairs for repopulating the form. Applies the CSS class "field_error" to each field with an error.
    # Availabe options are:
    #
    # errors: Array of field names with errors.
    # values: Hash of key/value pairs, where key is the field name.
    # selector: A CSS selector to provide scope.
    def prepare_form(xml, opts = {})
      doc = Nokogiri::HTML::Document.parse(xml)
      doc = doc.css(opts[:selector]) unless opts[:selector].nil?
      
      # Add error class to all fields with errors.
      unless opts[:errors].nil? || opts[:errors].empty?
        doc.css(opts[:errors].map { |v| "[name='#{v}']" }.join(", ")).each { |v| v['class'] = 'field_error' }
      end

      # Repopulate field with the given field values.
      unless opts[:values].nil? || opts[:values].empty?
        values = opts[:values]
        doc.css(values.keys.map { |k| "[name='#{k}']" }.join(", ")).each do |v|
          val = values[v['name']] || values[v['name'].to_sym]
          val = case val
            when Time
              #v.attributes.select{|v| v.name == 'type'}
              if v['type'] == 'date'
                val.strftime('%d/%m/%Y')
              elsif v['type'] == 'datetime'
                val.strftime('%d/%m/%Y %-I:%M%P')
              else
                ((val.hour + val.min + val.sec) > 0) ? val.strftime('%d/%m/%Y %l:%M%P') : val.strftime('%d/%m/%Y')
              end
            when nil
              ''
            else
              val.to_s
          end
          
          case v.name
            when 'input'
              v['value'] = val
            when 'select'
              v.css('option').each do |option|
                if val == option['value'] || (option['value'].nil? && option.content == val)
                  option['selected'] = 'selected'
                end
              end
            when 'textarea'
              v.content = val
          end
        end
      end
      (doc.nil?) ? str : Nokogiri::HTML::Builder.with(doc).to_html
    end
    
  end
end
