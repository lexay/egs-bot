require_relative 'bot_service'
require_relative 'egscraper'
require_relative 'template'

module EGS
  class Schedule
    def plan
      loop do
        release_date_ahead? ? EGS::LOG.info('Skipping to the next release!') : serve_games_to_users
        wait 'next_release'
      end
    end

    private

    def serve_games_to_users
      games = parse_games
      chat_ids = EGS::Models::User.chat_ids
      return EGS::LOG.info 'Games returned nothing! Skipping...' if games.empty?
      return EGS::LOG.info 'No subscribed users! Skipping...' if chat_ids.empty?

      store(games)
      EGS::LOG.info 'Games have been successfully saved to Database!'
      dispatch(games.count, chat_ids)
    end

    def parse_games
      5.times do
        promotions = EGS::Promotion::Parser.run
        return promotions unless promotions.empty?

        wait '5 mins'
      end
      []
    end

    def store(games)
      games.each do |game|
        EGS::Models::FreeGame.new(game).save
      end
    end

    def dispatch(count, chat_ids)
      games = EGS::Models::FreeGame.games(count)

      chat_ids.each do |chat_id|
        EGS::BOT.api.send_message(chat_id: chat_id, text: EGS::Template.new(games), parse_mode: 'html')
        EGS::LOG.info "Games have been dispatched to #{chat_id}!"

      # Telegram::Bot::Exceptions::ResponseError
      # Telegram API has returned the error. (ok: "false", error_code: "403",
      # description: "Forbidden: bot was blocked by the user")

      rescue => exception 
        EGS::LOG.error exception.message

        if process(exception)[:error_code] == '403'
          EGS::LOG.info "Invalid user(#{chat_id}). Unsubscribing..."
          EGS::Models::User.unsubscribe chat_id
        end

        next
      end
    end

    def process(exception)
      message = exception.message.match(/(?<=\().+(?=\))/).to_s
      message
        .split(',')
        .to_h { |k_v_pair| [k_v_pair[/\w+[^:]/], k_v_pair[/(?<=\").+[^"]/]] }
        .transform_keys(&:to_sym)
    end

    def wait(date)
      that_much = case date
                  when '5 mins'
                    60 * 5
                  when 'day'
                    60 * 60 * 24
                  when 'next_release'
                    time_to_next_release
                  end
      sleep that_much
    end

    def release_date_ahead?
      time_to_next_release.positive?
    rescue NoMethodError
      false
    end

    def time_to_next_release
      EGS::Models::FreeGame.next_date - Time.now
    end
  end
end
