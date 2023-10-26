module EGS
  class Scheduler
    class << self
      include TimeHelper

      def run
        loop do
          prepare_new_release
          wait
        end
      end

      private

      def prepare_new_release
        current_release = Models::Release.last
        return LOG.info('No new release yet! Skipping...') if current_release.time_left.positive?

        new_games = Promotion::Scraper.run
        return LOG.info('No games! Skipping...') if new_games.empty?

        current_games = current_release.free_games

        if current_games == new_games
          LOG.info('Games from OLD in NEW Release! Data for NEW Release is probably delayed!')
        else
          latest_new_game = new_games.sort.last
          new_release = Models::Release.create(
            start_date: latest_new_game.start_date,
            end_date: latest_new_game.end_date
          )
          new_games.each do |game|
            game.release_id = new_release.id
            game.save
          end
          LOG.info 'Games have been successfully saved to Database!'
        end

        Notifier.push(Formatter.format(new_games:, template: TelegramTemplate))
      end

      def wait
        time_left = Models::Release.last.time_left
        that_many_seconds = time_left.positive? ? time_left : ENV['TIMEOUT_SEC'].to_i
        LOG.info "Waiting: #{convert_to_human_readable(that_many_seconds)} ..."
        sleep that_many_seconds
      end
    end
  end
end
