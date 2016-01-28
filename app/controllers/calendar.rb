module Tombstone
  Root.controller '/calendar' do

    get '/' do
      render :'calendar/index'
    end

    get '/events', :media_type => 'application/json' do
      start_date_time = Time.at(request.GET['start'].to_i).to_datetime unless request.GET['start'].nil?
      end_date_time = Time.at(request.GET['end'].to_i).to_datetime unless request.GET['end'].nil?
      json_response Calendar.new.events(start_date_time, end_date_time)
    end

    get '/ics' do
      response['Content-Disposition'] = 'filename="interments.ics"'
      response['Content-Type'] = 'text/calendar'
      response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
      Calendar.new.iCal.export
    end
    
  end
end
