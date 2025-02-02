# Crow (crow-bot)
A Discord bot for playing music files (.mp3, .flac, or .wav) in a voice channel. Songs are added in a queue-like system, with basic controls for skipping songs in the queue, and pausing/playing. Crow can also queue all music files in a folder placed in the album directory to be played, either sequentially or shuffled.

## Requirements

- Ruby 3.1 or greater
- libsodium
- libopus
- ffmpeg

See [discord.rb's repo](https://github.com/shardlab/discordrb) for more instructions on installing these dependencies.

Required gems:
- discordrb
- dotenv

You can install these gems from the Gemfile by using the Bundler gem:
```
bundle install
```

## Use

Before playing music, Crow must be connected to a voice channel. When you're in a voice channel, type `~connect` (replacing `~` with your desired command prefix), and Crow will connect to your channel. Likewise, use `~disconnect` to disconnect Crow from the voice channel.

There are two commands for playing music:
- `~play [path_to_file]`
    - This will add a single music file to the queue when given a valid path to the file. You can use either absolute or relative path names.
    - If the file path has spaces, you can optionally wrap it in single or double quotes.
        - e.g. `~play "albums/my-album/this song has spaces.mp3"`
    - If no file name is given, this command causes playback of a song to continue if it was previously paused at some point.
- `~playalbum [-s] name_of_album`
    - This will add every music file in the given folder located in `albums/` to the queue.
        - The name of the folder **must not** have spaces for it to be recognized, however.
    - You can optionally add the flag `-s` to shuffle the queue after adding the album's songs
        - e.g. `~playalbum my-album -s` or `~playalbum -s my-album`

Crow will play each song in the queue until the queue is empty. The bot's profile status will update to show which song it is currently playing.

You can pause playback with `~pause`, and continue playback with `~play`. Typing `~stop` will clear all songs in the queue.

Typing `~help` will bring up a list of the available commands, and you can use `~help [command_name]` to get help for a specific command.

Other commands:
- `~albums` - lists all albums in the `albums/` directory
- `~queue` - lists all songs in the queue
- `~skip` - skips to the next song in the queue
- `~shuffle` - shuffles the order of songs currently in the queue
- `~quit` - terminates the program
- `~mew` - Crow says "mew!" :>


## Running

Before running Crow, you need to make a `.env` file in the program's directory. The following variables can be defined in this file:
- `CROW_TOKEN`  ---> your Discord bot's token (***required***)
- `CHANNEL_ID`  ---> the ID of a text channel for Crow to send statuses to (***required***)
- `CROW_PREFIX` ---> the command prefix to use for commands (***required***)
- `CROW_LOGGING` ---> the logging mode to use (default is `normal`)
    - other logging modes:
        - `debug` --> logs everything
        - `verbose` --> logs everything exccept debug messages
        - `quiet` --> only logs warnings and errors
        - `silent` --> logs nothing

Example `.env` file:
```
CROW_TOKEN=MY_BOT_TOKEN
CHANNEL_ID=TEXT_CHANNEL_ID
CROW_PREFIX='~'
CROW_LOGGING='verbose'
```

Included in this repo are start and stop Bash scripts (`start.sh` and `stop.sh`) which you can use for running Crow in the background. Any output/errors will get logged to `crow.log` if you use these scripts. Remember to make these scripts executable before running them.

Otherwise, you can run Crow using `bundle` via terminal:
```
bundle exec ruby crow.rb
```