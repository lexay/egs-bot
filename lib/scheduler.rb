module EGS
  class Schedule
    include TimeHelper

    def run
      loop do
        prepare_new_release
        wait
      end
    end

    private

    def prepare_new_release
      current_games = Models::Release.last.free_games
      return LOG.info('No new release yet! Skipping...') if fetch_time_left(current_games).positive?

      new_games = Promotion::Scraper.run
      return LOG.info('No games! Skipping...') if new_games.empty?
      return LOG.info('New games can not have expired date! Skipping...') if fetch_time_left(new_games).negative?

      if current_games == new_games
        current_games.each { |game| game.update(end_date: new_games.last.end_date) }
        LOG.info('Current release has been prolongated!')
      else
        new_release = Models::Release.create
        new_games.map do |game|
          game.release_id = new_release.id
          game.save
        end
        LOG.info 'Games have been successfully saved to Database!'
      end

      Notifier.push(Formatter.format(new_games:, template: TelegramTemplate))
    end

    def wait
      current_games = Models::Release.last.free_games
      time_left = fetch_time_left(current_games)
      that_many_seconds = time_left.positive? ? time_left + ENV['DELAY_SEC'].to_i : ENV['TIMEOUT_SEC'].to_i
      LOG.info "Sleeping: #{convert_to_human_readable(that_many_seconds)} ..."
      sleep that_many_seconds
    end
  end
end
