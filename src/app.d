import std.stdio, std.regex, std.json, std.algorithm;
import std.range;
import std.net.curl;
import ircbod.client, ircbod.message;

import jirabot.jiraapi;

// Move this stuff into configuration file at some point ...
auto JIRA_REX = regex(r"([A-Za-z0-9]{1,10}-?[A-Za-z0-9]+-\d+)");
string JIRA_SERVER = "http://jiraserver/rest/api/latest/";
string IRC_SERVER = "irc.example.com";
ushort IRC_PORT = 6667;
string IRC_BOT_NAME = "jirabot";
string[] IRC_CHANNELS = ["#dhr"];

/**
 * Given a message, parse out a list of potential JIRA issues.
 *
 * Returns: A list of potential jira issues.
 */
string[] parse_jira_issues(string msg)
{
    return matchAll(msg, JIRA_REX).map!(a => a.hit).array();
}
unittest
{
    assert(parse_jira_issues("dcc-123 is cool and DHR-123 gets -1 points") == ["dcc-123", "DHR-123"]);
    assert(parse_jira_issues("Hello World!") == []);
}

/**
 * Initialize an IRC bot with the given configuration.
 *
 * Returns: a new IRCClient object initialized with the values in conf.
 */
IRCClient initialize_bot(string[] conf)
{
    // TODO: Get configuration
    return new IRCClient(IRC_SERVER, IRC_PORT, IRC_BOT_NAME, null, IRC_CHANNELS);
}

void main(string[] args)
{
    IRCClient bot = initialize_bot(args);
    auto jira = new JiraAPI(JIRA_SERVER, "username", "password");

    // Possible Feature Additions:
    //   * Standup Time
    //   * Monitor JIRA board for Ticket State changes

    bot.on(IRCMessage.Type.CHAN_MESSAGE, (msg) {
        // check for JIRA ticket
        string[] issues = parse_jira_issues(msg.text);
        foreach (string key; issues)
        {
            string title = jira.issue(key);
            if ("" != title)
                msg.reply(key ~ ": " ~ title);
        }
    });

    bot.on(IRCMessage.Type.CHAN_MESSAGE, r"^!blocked$", (msg) {
        msg.reply("Getting blocked issues");
        foreach(string issue; jira.blocked_issues("dcc"))
            msg.reply(issue);
    });

    bot.run();
}
