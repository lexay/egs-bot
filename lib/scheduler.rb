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
      end

      def push_games
        games = Models::Game.where(pushed: false)
        return LOG.info(I18n.t(:no_new_release)) if games.empty?

        Notifier.push(Formatter.format(games:, template: TelegramTemplate))
        LOG.info(I18n.t(:pushed))
        games.each { |g| g.update(pushed: true) }
      end
    end
  end
end
