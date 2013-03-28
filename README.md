Splitmo
=======

A quick and dirty (*I wrote this in an hour or so*) ruby script to settle up
your [Splitwise](http://splitwise.com) account using [Venmo](http://www.venmo.com).

The script will run and email each person in the group that is owed money a link
to charge the various other members. It can also be run through a cron job to 
settle up a running group every month.

Installation
------------

1. Download repository
2. Edit the .splitmo config file with your email settings, splitwise API key and
group IDs. Get a Splitwise API Key [here](https://secure.splitwise.com/oauth_clients).
The group IDs can be gotten from the digits at the end of the url for a group.

Usage
-----

    ./splitmo.rb [CONFIG_LOCATION]

ToDo
----

 - Comment Code
 - Gemify Code
 - Add in help
 - Check for things that go boom!

