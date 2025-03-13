# Crow (crow-bot)
A Discord bot for playing music files (.mp3, .flac, or .wav) in a voice channel. Songs are added in a queue-like system, with basic controls for skipping songs in the queue, pausing/playing, and seeking to a later time in the song. Crow can also queue all music files in a folder placed in the album directory to be played, either sequentially or shuffled.

## Requirements

- Ruby 3.1 or greater
- libsodium
- libopus
- ffmpeg
- taglib 1.11.1 or greater, with dev headers

See [discord.rb's repo](https://github.com/shardlab/discordrb) for more instructions on installing libsodium and libopus.

On Ubuntu/Debian, you can install taglib 1.13.1 with dev headers with the following command:
```
sudo apt-get install libtag1-dev
```

Required gems:
- discordrb
- dotenv
- taglib-ruby

***Note: Depending on which version of taglib you have installed, you'll need to tweak your Gemfile for the bot to work.***

If you're using a taglib version below 2.0, then add this to your Gemfile:

```
gem 'taglib-ruby', '< 2.0'
```

Otherwise, add this to the Gemfile:
```
gem 'taglib-ruby', '>= 2.0'
```

Then, install the gems using Bundler:
```
bundle install
```

## Use

Before playing music, Crow must be connected to a voice channel. When you're in a voice channel, type `~connect` (replacing `~` with your desired command prefix), and Crow will connect to your channel. Likewise, use `~disconnect` to disconnect Crow from the voice channel.

There are two commands for playing music:
- `~play [path_to_file]` (alias: `~p`)
    - This will add a single music file to the queue when given a valid path to the file. You can use either absolute or relative path names.
    - If the file path has spaces, you must wrap it in double quotes.
        - e.g. `~play "albums/my-album/this song has spaces.mp3"`
    - If no file name is given, this command causes playback of a song to continue if it was previously paused at some point.
- `~playalbum [-s] name_of_album` (alias: `~pa`)
    - This will add every music file in the given folder located in `albums/` to the queue.
        - If the folder name has spaces, you must wrap it in double quotes.
            - e.g. `~playalbum "my music folder"`
    - You can optionally add the flag `-s` to shuffle the queue after adding the album's songs
        - e.g. `~playalbum my-album -s` or `~playalbum -s my-album`

Crow will play each song in the queue until the queue is empty. The bot's profile status will update to show which song it is currently playing.

You can also view what song Crow is currently playing with `~nowplaying` or `~np`, which displays the song title, artist, and how far Crow is in the song when you call the command. If the song file doesn't have a title specified in the metadata, the filename will be displayed instead.

![A screenshot of Crow displaying the current song with `nowplaying`](readme-imgs/crow-bot-scr1.png)

You can pause playback with `~pause`, and continue playback with `~play`. Typing `~stop` will clear all songs in the queue. You can also seek to a specified timecode in the song by using `~seek [H:MM:SS or MM:SS]` (or `~skip`), but note that Crow cannot go back in time (i.e. the timecode has already been passed).

Typing `~help` will bring up a list of the available commands, and you can use `~help [command_name]` to get help for a specific command.

Other commands:
- `~albums` - lists all albums in the `albums/` directory
- `~list my-album` - lists all songs in an album in the `albums/` directory

![A screenshot of Crow displaying the current song with `nowplaying`](readme-imgs/crow-bot-scr3.png)

- `~queue` or `~q` - lists all songs in the queue with length, title and artist

![A screenshot of Crow displaying the current song with `nowplaying`](readme-imgs/crow-bot-scr2.png)

- `~next` - moves to the next song in the queue
- `~shuffle` - shuffles the order of songs currently in the queue
- `~quit` - terminates the program
- `~mew` - Crow says "mew!" :>

## Running

Before running Crow, you need to make a `.env` file in the program's directory. The following variables can be defined in this file:
- `CROW_TOKEN`    ---> your Discord bot's token (***required***)
- `CROW_PREFIX`   ---> the command prefix to use for commands (***required***)
- `CROW_CHANNELS` ---> list of comma-separated channel IDs Crow can be used in (omit for Crow to be usable in any channel)
    - you can find a channel's ID by enabling Developer Mode in Discord's settings -> right-click channel -> Copy Channel ID
- `CROW_LOGGING`  ---> the logging mode to use (default is `normal`)
    - other logging modes:
        - `debug` --> logs everything
        - `verbose` --> logs everything exccept debug messages
        - `quiet` --> only logs warnings and errors
        - `silent` --> logs nothing

Example `.env` file:
```
CROW_TOKEN=MY_BOT_TOKEN
CROW_PREFIX='~'
CROW_CHANNELS=123,456,789
CROW_LOGGING='verbose'
```

Included in this repo are start and stop Bash scripts (`start.sh` and `stop.sh`) which you can use for running Crow in the background. Any output/errors will get logged to `crow.log` if you use these scripts. Remember to make these scripts executable before running them.

Otherwise, you can run Crow using `bundle` via terminal:
```
bundle exec ruby crow.rb
```