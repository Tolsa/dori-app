class GoogleCalendarWrapper
  def initialize(current_user)
    configure_client(current_user)
  end
  def configure_client(current_user)
    @client = Google::APIClient.new
    @client.authorization.access_token = current_user.token
    @client.authorization.refresh_token = current_user.refresh_token
    @client.authorization.client_id = ENV['GOOGLE_CLIENT_ID']
    @client.authorization.client_secret = ENV['GOOGLE_CLIENT_SECRET']
    @client.authorization.refresh!
    @service = @client.discovered_api('calendar', 'v3')
  end

  def calendar_id
    response = @client.execute(api_method:
    @service.calendar_list.list)
    calendars = JSON.parse(response.body)
    calendar = calendars["items"].find { |cal| cal["primary"] == true }
    return calendar["id"]
  end

  def send_calendar(program)
    events(program).each do |event|
      result = @client.execute(
        :api_method => @service.events.insert,
        :parameters => {
          'calendarId' => calendar_id,
          'sendNotifications' => true
        },
        :body => JSON.dump(event),
        :headers => {'Content-Type' => 'application/json'}
      )
      program.eventidgoogle = result.data.id
      program.save
    end
  end

  def delete_calendar(program)
    events(program).each do |event|
      @client.execute(
        :api_method => @service.events.delete,
        :parameters => {
          'calendarId' => calendar_id,
          'eventId' => program.eventidgoogle
        },
      )
    end
  end

  def events(program)
    mapping = {
      1 => "1_lundi",
      2 => "2_mardi",
      3 => "3_mercredi",
      4 => "4_jeudi",
      5 => "5_vendredi",
      6 => "6_samedi",
      7 => "7_dimanche"
    }

    range_week = (Date.today .. (Date.today + 6.days))
    events = []
    range_week.each do |day|
      day_name = mapping[day.wday]
      next unless program.cards_builder.has_key?(day_name)
      element = program.cards_builder[day_name]

      events << {
        "end": {
          "dateTime": day.iso8601+"T"+element["end"]+":00+01:00",
          "timeZone": "Europe/Paris"
        },
        "start": {
          "dateTime": day.iso8601+"T"+element["start"]+":00+01:00",
          "timeZone": "Europe/Paris"
        },
        "recurrence": [
          "RRULE:FREQ=WEEKLY"
        ],
        "description": element["training"],
        "summary": "Swim avec Dori 🐠",
        "location": element["okpool"]["address"],
        "reminders": {
          "overrides": [
            {
              "method": "sms",
              "minutes": 1440
            }
          ],
          "useDefault": false
        },
        "colorId": "5",
        "id": ""
      }
    end
    return events
  end
end

