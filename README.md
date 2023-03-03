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
[X] [Heroku version](https://github.com/lexay/epic_bot/tree/heroku).  
[X] Docker version. Now its the main version.

### CHANGES:
* Major release 1.0 6/26/2022
* Rewrite 10/30/2022 (check [old_version branch](https://github.com/lexay/epic_bot/tree/old_version) for the previous version of this bot)
* Docker version released. 12/20/2022

### How to use
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
