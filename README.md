# tskserver-notification-bot
Post notification to Twitter and Discord on login, server up, server down.
This bot uses https://github.com/k5342/minecraft-status-check-http-api to fetch Minecraft server status.

## Installation
1. clone this repository
2. `bundle install --path vendor/bundle`
3. copy from `.env.example` to `.env`
4. write your appropriate environment variables to `.env`
5. `bundle exec ruby main.rb` to run this application

## Example

### Twitter
[@tskserver](https://twitter.com/tskserver)

### Discord
Support Discord's rich Embed object
![rich embeds](https://pbs.twimg.com/media/DQ-jQmTVwAI9oWr.jpg:large)
