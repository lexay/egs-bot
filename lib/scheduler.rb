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
        return LOG.info(I18n.t(:no_new_release)) if current_release.time_left.positive?

        new_games = Promotion::Scraper.run
        return LOG.info(I18n.t(:no_games)) if new_games.empty?

        current_games = current_release.free_games
        return LOG.info(I18n.t(:delayed)) if current_games == new_games

        latest_new_game = new_games.sort.last
        new_release = Models::Release.create(
          start_date: latest_new_game.start_date,
          end_date: latest_new_game.end_date
        )
        new_games.each do |game|
          game.release_id = new_release.id
          game.save
        end
        LOG.info(I18n.t(:saved))

        Notifier.push(Formatter.format(new_games:, template: TelegramTemplate))
        LOG.info(I18n.t(:pushed))
      end

      def wait
        time_left = Models::Release.last.time_left
        that_many_seconds = time_left.positive? ? time_left : ENV['TIMEOUT_SEC'].to_i
        time_human = convert_to_human_readable(that_many_seconds)
        LOG.info(I18n.t(:time_table, **time_human))
        sleep that_many_seconds
      end
    end
  end
end
