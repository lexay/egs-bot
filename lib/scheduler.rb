module EGS
  class Schedule
    include TimeHelper

    def plan
      Thread.new do
        loop do
          prepare_new_release
          serve_games_to_users
          wait 'next_release'
        end
      end
    end

    private

    def prepare_new_release
      return EGS::LOG.info('Skipping to the next release!') if release_date_ahead?

      EGS::Models::Release.init
      games = fetch_parsed_games
      store(games)
    end

    def fetch_parsed_games
      5.times do
        promotions = EGS::Promotion::Parser.run
        return promotions unless promotions.empty?

        wait '5 mins'
      end
      []
    end

    def store(games)
      games.each(&:save)
      EGS::LOG.info 'Games have been successfully saved to Database!'
    end

    def serve_games_to_users
      last_release = EGS::Models::Release.last || EGS::Models::Release.init
      chat_ids_queued = JSON.parse(last_release.chat_ids_not_served)
      return EGS::LOG.info 'All users have received the released games! Skipping...' if chat_ids_queued.empty?

      dispatch(last_release.free_games, chat_ids_queued)
    end

    def dispatch(count, chat_ids)
      chat_ids.reverse_each do |chat_id|
        EGS::BotClient.api.send_message(chat_id: chat_id, text: EGS::Template.new(games), parse_mode: 'html')
        EGS::LOG.info "Games have been dispatched to #{chat_id}!"
        chat_ids.pop
        EGS::Models::Release.last.update(chat_ids_not_served: chat_ids).save

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
  end
end
