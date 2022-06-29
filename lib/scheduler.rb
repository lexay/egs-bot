module EGS
  class Schedule
    include BotHelper
    include GameHelper
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
      return EGS::LOG.info('No new release yet! Skipping...') if time_to_next_release.positive?

      current_games = EGS::Promotion::Parser.run
      last_games = EGS::Models::Release.last.free_games

      def current_games.release_date_empty?
        self.empty? || self.first.end_date.nil?
      end

      return EGS::LOG.info('Empty date! Skipping...') if current_games.release_date_empty?
      return EGS::LOG.info('Release same as last one! Skipping...') if current_games == last_games

      EGS::Models::Release.init
      current_games.map { |game| game.release_id = EGS::Models::Release.last.id }
      store(current_games)
    end

    def store(games)
      games.each(&:save)
      EGS::LOG.info 'Games have been successfully saved to Database!'
    end

    def serve_games_to_users
      chat_ids = JSON.parse(latest_release.chat_ids_not_served)
      return EGS::LOG.info 'No queued users! Skipping...' if chat_ids.empty?
      return EGS::LOG.info 'No games! Skipping...' if latest_games.empty?

      dispatch(formatted_latest_games, chat_ids)
    end

    def dispatch(games, chat_ids)
      chat_ids.reverse_each do |chat_id|
        send_message(games, chat_id)
        EGS::LOG.info "Games have been dispatched to #{chat_id}!"
        dequeue_and_update(chat_ids)

      # Telegram::Bot::Exceptions::ResponseError
      # Telegram API has returned the error. (ok: "false", error_code: "403",
      # description: "Forbidden: bot was blocked by the user")

      rescue => e
        EGS::LOG.error e.message

        if process(e)[:error_code] == '403'
          EGS::LOG.info "Invalid user(#{chat_id}). Unsubscribing..."
          EGS::Models::User.unsubscribe chat_id
          dequeue_and_update(chat_ids)
        end
      end
      EGS::LOG.info 'All users have received the current games!'
    end

    def process(exception)
      message = exception.message.match(/(?<=\().+(?=\))/).to_s
      message
        .split(',')
        .to_h { |k_v_pair| [k_v_pair[/\w+[^:]/], k_v_pair[/(?<=\").+[^"]/]] }
        .transform_keys(&:to_sym)
    end

    def dequeue_and_update(chat_ids)
      chat_ids.pop
      latest_release.update(chat_ids_not_served: chat_ids.to_json)
    end

    def wait(date)
      that_much = case date
                  when '5 mins'
                    60 * 5
                  when 'day'
                    60 * 60 * 24
                  when 'next_release'
                    time = time_to_next_release
                    time.positive? ? time + 30 : 60 * 60 * 5
                  end
      EGS::LOG.info "Sleeping for: #{seconds_to_human_readable(that_much)}..."
      sleep that_much
    end
  end
end
