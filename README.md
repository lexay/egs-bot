### A few words about how this all started
This is my own first 'big' project in software development. It was intended for
a friend who did not want any games released by Epic Games Store for free
slipping behind his ears.

I started it as a total noob, and as the project grew and I got more skilled
with Ruby (my favorite programming language btw!) it received more valuable
updates.

### About the project
And this app's sole purpose is to scrape info about the free games, released by
EGS and push notifications to subscribed users in Telegram. (love scraping and
web crawlers btw!)

##### Features:
App sends the name, description and link of EGS's freebies to subscribed users
in Telegram via a bot. It could retrieve more information at the early stage of
its development, but I decided the data was enough to get the idea what's being
released. The app got a simplier interface.

App is designed to work on a free tier instance of Heroku. The app leverages
Ruby Threads to overcome the free tier limitations for > 1 launched processes
atst there, so it forks the main process.

App loops over its tasks, it will retry if one of the tasks fails. It waits till
the next release date after all tasks have succeeded. 

App handles subscribing and unsubscribing users to the bot properly. All users
subscribed to the bot are saved to your DB, so you will not lose them
accidentally.

App also saves the state if the user got hes/hers much needed information about
the released games, so the bot will not make the users angry by sending them the
same data over and over again in case this task fails(esp. repeatedly).

### TODO
I wanna dive into Docker some more(exciting piece of Tech!) in the future, so
upcoming commits or a new branch even may also include Docker files.

### CHANGES:
* Major release 1.0 6/26/2022

### How to use
1. Get your Telegram Bot instance and set it up. [tutorial](https://core.telegram.org/bots#3-how-do-i-create-a-bot)
2. Clone the project `git clone https://github.com/lexay/epic_bot.git`.
3. Make your own locale config in `./config/locales/` if needed.
4. Adjust the app options in `start.rb` if needed.
6. Deploy to Heroku. I personally recommend using the Heroku CLI. [tutorial](https://devcenter.heroku.com/articles/git)
7. Setup your Heroku instance of a PostgreSQL DB. [tutorial](https://devcenter.heroku.com/articles/heroku-postgresql)
8. Set the environment variables for your Telegram Bot and DB on Heroku. [tutorial](https://devcenter.heroku.com/articles/config-vars)
9. Start the app! :-)
