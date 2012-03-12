module Tombstone
  class Calendar
    def iCal(days = 21)
      RiCal.Calendar do |cal|
        cal.prodid "-//Tablelands Regional Council//Tombstone//EN"
        cal.method_property ":REQUEST"
        Interment.filter(:interment_date => (Date.today - 7)..(Date.today + days)).all.each { |interment|
          cal.event do |event|
            event.summary format_event_description(interment)
            event.uid = interment.id.to_s << "-tombstone.trc.local"
            event.sequence = interment.id
            event.description self.full_description(interment)
            event.dtstart interment.interment_date.set_tzid(:floating)
            event.dtend interment.interment_date_end.set_tzid(:floating)
            event.location interment.place.description
            event.dtstamp DateTime.now.set_tzid(:floating)
            event.add_comment self.format_event_comments(interment)
            event.organizer "noreply@tombstone.trc.qld.gov.au"
          end
        }
      end
    end

    def events(start_date_time, end_date_time)
      events = []
      Interment.filter(:interment_date => start_date_time..end_date_time).all.each { |interment|
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

    def format_short_event_description(interment)
      "[" << interment.status.capitalize << "] " << ((interment.roles_by_type('deceased')[0] == nil) ? "<Deceased Name Pending>" : interment.roles_by_type('deceased')[0].person.title \
          << " " << interment.roles_by_type('deceased')[0].person.given_name << " " << interment.roles_by_type('deceased')[0].person.surname) \
          << " - " << interment.place.description
      end

    def format_event_description(interment)
      "[" << interment.status.capitalize << "] " << ((interment.roles_by_type('deceased')[0] == nil) ? "<Deceased Name Pending>" : interment.roles_by_type('deceased')[0].person.title \
          << " " << interment.roles_by_type('deceased')[0].person.given_name << " " << interment.roles_by_type('deceased')[0].person.surname) \
          << " - " << interment.interment_type.to_s.capitalize << " with " \
          << ((interment.funeral_director == nil) ? "<Funeral Director Pending>" : interment.funeral_director.name)
    end

    def format_event_comments(interment)
      "\n\nBurial Requirements:\n" << ((interment.burial_requirements == nil) ? "No burial requirements" : interment.burial_requirements) \
          << "\n\nComments:\n" << ((interment.comments == nil) ? "No comments" : interment.comments)

    end

    def full_description(interment)
      self.format_event_description(interment) << " " << self.format_event_comments(interment)
    end

  end
end

