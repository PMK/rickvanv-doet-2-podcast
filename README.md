# DESCRIPTION

> https://pmklaassen.com/rickvanv-doet-2/

Append latest podcast (RickvanV doet 2) to feed.

# INSTALLATION

This will run the cronjob once every Monday to Thursday at 7am:

```
$ sudo crontab -e

0 7 * * 1-4 ./update-podcast-feed.sh >/dev/null 2>&1
```

# DEPENDENCIES

- [jq](https://github.com/stedolan/jq)
- [pup](https://github.com/ericchiang/pup)
- language-pack-nl (only for Linux) [optional]
- coreutils (only for macOS; see below)

Dependencies can be downloaded to a `./bin/` directory.

## TO DO ON macOS ONLY:

1. install coreutils `$ brew install coreutils`
2. check if command 'gdate' exists (is installed via coreutils)
3. append the code below to your `.bashrc`
4. don't forget to source your .bashrc `$ source ~/.bashrc`
5. test this command (should return no errors) `$ date --date "2019-03-14T04:00:00+01:00" "+%F"`

```
# copy this to your .bashrc
PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
```
