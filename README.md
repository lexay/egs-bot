## Table of Contents:
- [How it all started](#a-few-words-about-how-this-all-started)
- [About the Project](#about-the-project)
- [TODO](#todo)
- [Changes](#changes)
- [How to use with Telegram](#how-to-use-with-telegram-bot)
- [How to use with other bots (e.g., Discord)](#how-to-use-with-other-bots)

### A few words about how this all started

This is my own first 'big' project in software development. It was intended for
a friend who did not want any games released by Epic Games Store for free
slipping behind his ears.

I started it as a total noob, and as the project grew and I got more skilled
with Ruby (my favorite programming language btw!) it received more valuable
updates.

### About the project

1. This app's sole purpose is to scrape info about the free games, when they are
   released by EGS. Love scraping and web crawlers btw!

2. Then the app sends the name, description and link of EGS's freebies to
   subscribed users to a specific channel in Telegram via a bot.

The Scraper part of the app could retrieve more information at the early stage
of its development, but I decided the data was enough to get the idea what's
being released. The app got a simplier interface.

### TODO

- [X] [Heroku version](https://github.com/lexay/epic_bot/tree/heroku).  
- [X] Docker version. Now its the main version.

### CHANGES

* Major release 1.0 6/26/2022
* Rewrite 10/30/2022 (check [old_version branch](https://github.com/lexay/epic_bot/tree/old_version) for the previous version of this bot)
* Docker version released. 12/20/2022

### How to use with Telegram Bot

1. Get your Telegram Bot instance and set it up. [tutorial](https://core.telegram.org/bots#3-how-do-i-create-a-bot)
2. Create a channel in Telegram.
3. Add your Bot as Admin of the channel.
4. Clone the project `git clone https://github.com/lexay/epic_bot.git` to your
   server.
5. Make your own locale config in `./config/locales/` if needed.
6. Adjust the app options in `start.rb` if needed.
7. Set the environment variables in the `.env` file in the project root directory:  
```
   POSTGRES_DB=  
   POSTGRES_USER=  
   POSTGRES_PASSWORD=  
   TG_TOKEN=  
   TG_CHANNEL=  
   DELAY_SEC=60  
   TIMEOUT_SEC=1800  
```
8. Build and deploy with `docker-compose`. [tutorial](https://docs.docker.com/engine/reference/commandline/compose/)

### How to use with other bots

Let's notify users of your lovely Discord Server about EpicStore Freebies!
1. Repeat steps 4 and 5 from the previous section.
2. Create and set up your bot.  
   For a Discord bot, we will create [a webhook](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks).  
   Save your generated `webhook` url to your `.env` file as `DISCORD_WEBHOOK`.  
   ```
   #.env
   #...
   DISCORD_WEBHOOK="<your_webhook>"
   #...
   ```
   Set up the other environment variables from step 7 from the previous section
   excluding the Telegram specific ones, if you dont need it.

3. Let's grab a `gem` to control our bot using Ruby:

   ```ruby
   #Gemfile
   #...
   gem 'discordrb', require: 'discordrb/webhooks'
   #...
   ```

4. Instantiate your bot in `start.rb`.

   ```ruby
   #start.rb
   #...
   DISCORD_BOT = Discordrb::Webhooks::Client.new(url: ENV['DISCORD_WEBHOOK'])
   #...
   ```

5. Implement `message` method in your custom `Template` child class (default
   template will be used otherwise).

   ```ruby
   #lib/template.rb
   module EGS
   #...
   class DiscordTemplate < DefaultTemplate
      def self.message(game)
         <<~MESSAGE
         **#{I18n.t(:title)}:** #{game.title}

         **#{I18n.t(:devs)}:** #{[game.publisher, game.developer].compact.uniq.join(' - ')}

         **#{I18n.t(:description)}:**
         #{game.description.truncate(300, separator: '.')}

         MESSAGE
      end
   end
   end
   ```

6. Implement `push` method in `Notifier` class.

   ```ruby
   #lib/notifier.rb
   module EGS
     class Notifier
       def self.push(text)
          DISCORD_BOT.execute { |builder| builder.content = text }
       end
     end
   end
   ```

7. Run task in `scheduler.rb`.

    ```ruby
    #lib/scheduler.rb
    #...
    def prepare_new_release
      #...
      Notifier.push(Formatter.format(new_games:, template: DiscordTemplate))
    end
    #...
    ```
