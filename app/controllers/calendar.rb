module Tombstone
  App.controller :calendar do

    get :index, :provides => :html do
      render "calendar/index"
    end

    get :events, :provides => :json do
      start_date_time = Time.at(params['start'].to_i).to_datetime unless params['start'].nil?
      end_date_time = Time.at(params['end'].to_i).to_datetime unless params['end'].nil?
      Calendar.new.events(start_date_time, end_date_time).to_json
    end

    get :ics do
      attachment 'interments.ics'
      content_type 'text/calendar'
      expires 0
      cache_control :no_cache, :no_store, :must_revalidate
      Calendar.new.calendar.iCal.export
    end
  end
end


