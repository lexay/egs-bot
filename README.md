### A few words about how this all started
This is my first big project. It was intended for a friend who
did not want any free release from EGS slipping behind his ears.

I started it as a total noob, and as the project grew and I got more skilled
with Ruby (my favorite programming language btw!) it received more valuable
updates.

### About the project
And this app's sole purpose is to scrape info about the free games, released by
EGS and push notifications to subscribed users in Telegram. (love scraping and
web crawlers btw!)

Note: Some countries do not have those freebies, but you can bypass it for now
by changing your region temporarily with the help of VPN.

App on the main branch(this one) is designed to work on a free tier instance of
Heroku. The app leverages Ruby Threads to overcome the free tier limitations
for > 1 launched processes atst and for practice and fun.

I wanna dive into Docker some more(exciting piece of Tech!) in the future, so
upcoming commits may come also into a new Docker branch.

### How to use
1. Pull the project.
2. Get your Telegram Bot instance. [tutorial](https://core.telegram.org/bots#3-how-do-i-create-a-bot)
3. Setup your Heroku instance of PostgreSQL DB. [tutorial](https://devcenter.heroku.com/articles/heroku-postgresql)
4. Deploy to Heroku. I personally recommend using the Heroku CLI. [tutorial](https://devcenter.heroku.com/articles/git)
5. Configure environment variables for your Telegram Bot and DB. [tutorial](https://devcenter.heroku.com/articles/config-vars)

TODO:
* [] Docker version.

CHANGES:
* Major release 1.0 6/26/2022

App got I18n implemented for you folks from around the globe who may wanna use
it. See the description how to do it in any of the locales in `~config/locales/`
:-)
