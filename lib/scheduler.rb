module EGS
  class Schedule
    include BotHelper
    include GameHelper
    include TimeHelper

    def run
      loop do
        prepare_new_release
        wait
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
        EGS::LOG.info('Current release has been prolongated!')
      else
        new_release = EGS::Models::Release.create
        new_games.map { |game| game.release_id = new_release.id }
        store(new_games)
      end
      send_to_channel(new_games)
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

    def wait
      current_games = query_release.free_games
      time_left = fetch_time_left(current_games)
      that_much_seconds = time_left.positive? ? time_left + ENV['DELAY_SEC'].to_i : ENV['TIMEOUT_SEC'].to_i
      EGS::LOG.info "Sleeping for: #{convert_to_human_readable(that_much_seconds)}..."
      sleep that_much_seconds
    end
  end
end
