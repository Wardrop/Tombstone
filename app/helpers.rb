module Tombstone
  module Helpers

    def json_response(obj = {})
      response['Cache-Control'] = 'no-cache'
      if Hash === obj
        obj[:errors] = nil if obj[:errors] && obj[:errors].empty?
        obj[:warnings] = nil if obj[:warnings] && obj[:warnings].empty?
        response.status = 500 if obj[:errors] || obj[:warnings]
      end
      obj.to_json
    end

    def include_script_views(*names)
      names.each do |name|
        document[:scripts] << "views/#{name}.js"
        content_for :head do
          render(File.expand_path("views/script_templates/#{name}").to_sym, :layout => false)
        end
      end
    end

    def build_breadcrumb(segments = nil)
      uri = ''
      request.matched_path.gsub(/^\/+/, '').split(/\/+/).map { |segment|
        uri = File.join(uri, segment)
        title = segment.gsub('_',' ').titleize
        "<a href='#{absolute uri}' class='breadcrumb'>#{title}</a>"
      }.unshift("<a href='#{absolute '/'}' class='breadcrumb home'></a>").join('<span class="breadcrumb div">/</span>')
    end

    # Renders field data, handling nil values and formatting of objects such as Dates.
    # Can take an optional block which has the advantage of being error-handled (e.g. calling a method on a nil object).
    def print(fallback = '<small>none</small>', &block)
      value = block.call rescue nil
      if value.blank?
        fallback
      else
        case value
          when Time, DateTime, Date
            ((value.hour + value.min + value.sec) > 0) ? value.strftime('%d/%m/%Y %l:%M%P') : value.strftime('%d/%m/%Y')
          else
            value
        end
      end
    end

    def print_simple_day(day_date)
      today = Date.today
      case day_date.strftime('%d/%m/%Y')
        when today.strftime('%d/%m/%Y')
          "Today"
        when (today + 1).strftime('%d/%m/%Y')
          "Tomorrow"
        else
          day_date.strftime('%A - %d/%m/%Y')
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
      document = Nokogiri::HTML::Document.parse(xml)
      working_set = opts[:selector].nil? ? document : document.css(opts[:selector]) unless

      # Add error class to all fields with errors.
      unless opts[:errors].nil? || opts[:errors].empty?
        working_set.css(opts[:errors].map { |v| "[name='#{v}']" }.join(", ")).each { |v| v['class'] = 'field_error' }
      end

      # Repopulate field with the given field values.
      unless opts[:values].nil? || opts[:values].empty?
        values = opts[:values]
        working_set.css(values.keys.map { |k| "[name='#{k}']" }.join(", ")).each do |v|
          val = values[v['name']] || values[v['name'].to_sym]
          val = case val
          when Date, Time
            if v['type'] == 'date'
              val.strftime('%F')
            elsif v['type'] == 'datetime'
              val.strftime('%FT%T')
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
              if v.css('option').any? { |option|
                  if val == option['value'] || (option['value'].nil? && option.content == val)
                    option['selected'] = 'selected'
                  end
                }
              else
                v << document.create_element("option", val, selected: 'selected') unless val.blank?
              end
            when 'textarea'
              v.content = val
          end
        end
      end
      (document.nil?) ? str : Nokogiri::HTML::Builder.with(document).to_html
    end

  end
end
