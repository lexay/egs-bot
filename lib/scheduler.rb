module EGS
  class Scheduler
    class << self
      def run
          prepare_new_release
      end

      private

      def prepare_new_release
        current_release = Models::Release.last
        return LOG.info(I18n.t(:no_new_release)) if current_release.time_left.positive?

        new_games = Scraper.run
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

      end
    end
  end
end
