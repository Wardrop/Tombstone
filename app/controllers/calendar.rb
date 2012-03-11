module Tombstone
  App.controller :calendar do

    get :index, :provides => :html do
      render "calendar/index"
    end

    get :events, :provides => :json do
      startTime = Time.at(params['start'].to_i).to_datetime unless params['start'].nil?
      endTime = Time.at(params['end'].to_i).to_datetime unless params['end'].nil?
      puts "Requested - " << startTime.to_s << " " << endTime.to_s
      calendar = Calendar.new
      calendar.events.to_json
    end

    get :ics do
      calendar = Calendar.new
      attachment 'interments.ics'
      content_type 'text/calendar'
      expires 0
      cache_control :no_cache, :no_store, :must_revalidate
      calendar.iCal.export
    end
  end
end


