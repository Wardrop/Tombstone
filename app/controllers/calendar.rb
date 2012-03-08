module Tombstone
  App.controller :calendar do
    get :index do
      calendar = Calendar.new
      attachment 'interments.ics'
      content_type 'text/calendar'
      expires 0
      cache_control :no_cache, :no_store, :must_revalidate
      calendar.iCal.export
    end
  end
end


