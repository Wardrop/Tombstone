module Tombstone
  class Calendar
    def iCal(days = 21)
      RiCal.Calendar do |cal|
        cal.prodid "-//Tablelands Regional Council//Tombstone//EN"
        cal.method_property ":REQUEST"
        Interment.filter(:interment_date => (Date.today - 7)..(Date.today + days)).order(:interment_date).all.each { |interment|
          cal.event do |event|
            event.summary format_event_description(interment)
            event.uid = interment.id.to_s << "-tombstone.trc.local"
            event.sequence = interment.id
            event.description self.full_description(interment)
            event.dtstart interment.interment_date.set_tzid(:floating)
            event.dtend interment.interment_date_end.set_tzid(:floating)
            event.location interment.place.description
            event.dtstamp DateTime.now.set_tzid(:floating)
            event.add_comment self.format_comments(interment)
            event.organizer "noreply@tombstone.trc.qld.gov.au"
          end
        }
      end
    end

    def events(start_date_time, end_date_time)
      events = []
      self.upcoming_interments(start_date_time, end_date_time).all.each { |interment|
        events << {
            :id => interment.id,
            :start => interment.interment_date.iso8601,
            :end => interment.interment_date_end.iso8601,
            :title => format_short_event_description(interment),
            :status => interment.status
        }
      }
      events
    end

    def upcoming_interments(start_date_time, end_date_time)
      Interment.filter(:interment_date => (start_date_time.to_datetime)..(end_date_time.to_datetime)).order(:interment_date)
    end

    def outstanding_tasks
      Interment.filter(:status => Interment.awaiting_action_states ).order(:interment_date)
    end

    def format_short_event_description(interment)
      self.format_status_and_deceased(interment) << " - " << interment.place.description
    end

    def format_event_description(interment)
      self.format_status_and_deceased(interment) \
          << " - " << interment.interment_type.to_s.capitalize << " with " \
          << ((interment.funeral_director == nil) ? "<Funeral Director Pending>" : interment.funeral_director.name)
    end

    def format_comments(interment)
      "\n\nBurial Requirements:\n" << ((interment.burial_requirements == nil) ? "No burial requirements" : interment.burial_requirements) \
          << "\n\nComments:\n" << ((interment.comments == nil) ? "No comments" : interment.comments)
    end

    def full_description(interment)
      self.format_event_description(interment) << " " << self.format_comments(interment)
    end

    def format_status_and_deceased(interment)
      "[#" << interment.id.to_s << "] " << self.format_deceased(interment)
    end

    def format_deceased(interment)
      deceased = interment.role_by_type('deceased')
      if deceased
        "#{interment.role_by_type('deceased').person.title} #{interment.role_by_type('deceased').person.given_name} #{interment.role_by_type('deceased').person.middle_name} #{interment.role_by_type('deceased').person.surname}"
      else
        "<Deceased Name Pending>"
      end
    end

  end
end

