#!/bin/bash

# DESCRIPTION:
# Append latest podcast (RickvanV doet 2) to feed
#   @author: PMK
#   @since: 2019/03
#   @license: MIT - https://pmk.mit-license.org
#   @dependencies: jq, pup, language-pack-nl (Linux only), coreutils (macOS only)
#   @see: https://pmklaassen.com/rickvanv-doet-2/
#
# INSTALLATION:
# this will run the cronjob once every Monday to Thursday at 7am
# $ sudo crontab -e
#   0 7 * * 1-4 ./update-podcast-feed.sh >/dev/null 2>&1
#
# DEPENDENCIES:
# - jq (https://github.com/stedolan/jq)
#      $ apt-get install jq
#      or download it to ./bin
# - pup (https://github.com/ericchiang/pup)
#      $ go get github.com/ericchiang/pup
#      or download it to ./bin
# - language-pack-nl (only for Linux) [optional]
#      $ apt-get install language-pack-nl
# - coreutils (only for macOS; see below)
#
# TO DO ON macOS ONLY:
# 1. install coreutils
#      $ brew install coreutils
# 2. check if command 'gdate' exists (is installed via coreutils)
# 3. append the following to your .bashrc
#      PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
#      MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
# 4. don't forget to source .bashrc
#      $ source ~/.bashrc
# 5. test this command (should return no errors)
#      $ date --date "2019-03-14T04:00:00+01:00" "+%F"

safe_pup() {
  if hash pup 2>/dev/null; then
    pup "$@"
  else
    if [ -f ./bin/pup ]; then
      ./bin/pup "$@"
    else
      echo "Dependency 'pup' not found!"
      exit 1
    fi
  fi
}

safe_jq() {
  if hash jq 2>/dev/null; then
    jq "$@"
  else
    if [ -f ./bin/jq ]; then
      ./bin/jq "$@"
    else
      echo "Dependency 'jq' not found!"
      exit 1
    fi
  fi
}

PODCAST_FEED_FILE="./public/podcast.rss"
TMP_FEED="/tmp/rick-podcast-feed"

USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36"
DATA_SHOW_URL="https://www.nporadio2.nl/?option=com_ajax&plugin=broadcasts&format=json&current_page=1&per_page=1&programme_id=6571&channel=2"
EPISODE_URL_PREFIX="https://www.nporadio2.nl/rickvanvdoet2/gemist/uitzending"

EPISODE_DATE=$(curl --silent -H "User-Agent: $USER_AGENT" "$DATA_SHOW_URL" | safe_jq ".data[0][0].rb_stopdatetime")
EPISODE_DATE="${EPISODE_DATE%\"}"
EPISODE_DATE="${EPISODE_DATE#\"}"
# 2019-03-14T04:00:00+01:00

DATE_EPISODE=$(date --date "$EPISODE_DATE" "+%F")
DATE_NOW=$(date "+%F")
if [ $DATE_EPISODE != $DATE_NOW ]; then
  echo "No new episode found."
  exit
fi

BKP_LC_ALL=$LC_ALL
if locale -a | grep -cq 'nl_NL.UTF-8'; then LC_ALL=nl_NL.UTF-8; fi
if locale -a | grep -cq 'nl_NL.utf8'; then LC_ALL=nl_NL.utf8; fi
EPISODE_DATE_FORMATTED_LABEL=$(date --date "$EPISODE_DATE" "+%A %d %B %Y")
LC_ALL=$BKP_LC_ALL
# woensdag 13 maart 2019

EPISODE_DATE_FORMATTED_URI=$(date --date "$EPISODE_DATE" "+%d-%m-%Y")
# 13-03-2019

EPISODE_DATE_FORMATTED_PUBLICATION=$(date --date "$EPISODE_DATE" "+%a, %d %b %Y %T %z")
# Wed, 13 Mar 2019 04:00:00 +0100

EPISODE_ID=$(curl --silent -H "User-Agent: $USER_AGENT" "$DATA_SHOW_URL" | safe_jq ".data[0][0].radiobox_broadcast_id")
EPISODE_ID="${EPISODE_ID%\"}"
EPISODE_ID="${EPISODE_ID#\"}"
# 259396

EPISODE_URL_FULL="$EPISODE_URL_PREFIX/$EPISODE_ID"

EPISODE_AUDIO_URL=$(curl --silent -H "User-Agent: $USER_AGENT" "$EPISODE_URL_FULL" | safe_pup "audio > source json{}" | safe_jq ".[0].src")
EPISODE_AUDIO_URL="${EPISODE_AUDIO_URL%\"}"
EPISODE_AUDIO_URL="${EPISODE_AUDIO_URL#\"}"
# //radiobox2.omroep.nl/broadcaststream/file/545584.mp3

head -n -3 $PODCAST_FEED_FILE > $TMP_FEED
tee -a $TMP_FEED >/dev/null <<__EOF
  <item>
    <title>Uitzending $EPISODE_DATE_FORMATTED_LABEL</title>
    <link>$EPISODE_URL_FULL/$EPISODE_DATE_FORMATTED_URI</link>
    <enclosure url="https:$EPISODE_AUDIO_URL" type="audio/mp3" />
    <guid isPermaLink="true">$EPISODE_URL_FULL/$EPISODE_DATE_FORMATTED_URI</guid>
    <pubDate>$EPISODE_DATE_FORMATTED_PUBLICATION</pubDate>
    <itunes:duration>2:00:00</itunes:duration>
  </item>
</channel>
</rss>

__EOF

cat $TMP_FEED > $PODCAST_FEED_FILE
rm -f $TMP_FEED
