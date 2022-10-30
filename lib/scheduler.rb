module EGS
  class Schedule
    include BotHelper
    include GameHelper
    include TimeHelper

    def run
      loop do
        prepare_new_release
        wait 'next_release'
      end
    end

    private

    def prepare_new_release
      current_games = query_release.free_games
      return EGS::LOG.info('No new release yet! Skipping...') if fetch_time_left(current_games).positive?

      new_games = EGS::Promotion::Scraper.run
      return EGS::LOG.info('No games! Skipping...') if new_games.empty?
      return EGS::LOG.info('New games can not have expired date! Skipping...') if fetch_time_left(new_games).negative?

      if current_games == new_games
        current_games.each { |game| game.update(end_date: new_games.last.end_date) }
        EGS::LOG.info('Old release has been prolongated!')
      else
        new_release = EGS::Models::Release.create
        new_games.map { |game| game.release_id = new_release.id }
        store(new_games)
        send_to_channel(new_games)
      end
    end

    def store(games)
      games.each(&:save)
      EGS::LOG.info 'Games have been successfully saved to Database!'
    end

    def send_to_channel(games)
      formatted_games = format(games)
      send_message(formatted_games, ENV['CHANNEL'])
      EGS::LOG.info 'Games have been dispatched to the channel!'
    end

    def wait(date)
      that_much = case date
                  when '5 mins'
                    60 * 5
                  when 'day'
                    60 * 60 * 24
                  when 'next_release'
                    current_games = query_release.free_games
                    time = fetch_time_left(current_games)
                    time.positive? ? time + 30 : 60 * 60 * 5
                  end
      EGS::LOG.info "Sleeping for: #{convert_seconds_to_human_readable(that_much)}..."
      sleep that_much
    end
  end
end
