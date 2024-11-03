module EGS
  class Scheduler
    class << self
      def run
        prepare_games
        push_games
      end

      private

      def prepare_games
        games = Scraper.run
        games.each do |g|
          new_g = Models::Game.new(g)
          new_g.save
          LOG.info(I18n.t(:saved, title: new_g.title))
        rescue Sequel::ValidationFailed => e
          LOG.info("#{new_g.title}'s #{e.message}")
          next
        end

        Notifier.push(Formatter.format(new_games:, template: TelegramTemplate))
        LOG.info(I18n.t(:pushed))
      end

      end
    end
  end
end
