module jirabot.jiraapi;

import std.regex;
import std.algorithm;
import std.range;
import std.uri;
import std.json;
import std.net.curl;

class JiraAPI
{
private:
    auto issue_regex = regex(r"([A-Za-z0-9]{1,10}-?[A-Za-z0-9]+-\d+)");
    string server;
    string username;
    string password;

    string query(string q)
    {
        auto client = HTTP();
        string buffer;
        client.url = this.server ~ encode(q);
        client.setAuthentication(this.username, this.password);
        client.onReceive = (ubyte[] data) { buffer ~= data; return data.length; };
        client.perform();

        return buffer;
    }

public:
    this(string server, string username, string password)
    {
        this.server = server;
        this.username = username;
        this.password = password;
    }

    string[] blocked_issues(string project)
    {
        auto json = parseJSON(this.query(
            "search?jql=PROJECT=" ~ project ~ " AND cf[10210]=Impediment"
        ));
        return json["issues"].array.map!(a => a["key"].str ~ ": " ~ a["fields"]["summary"].str).array();
    }

    string issue(string key)
    {
        auto json = parseJSON(this.query(
            "issue/" ~ key
        ));

        try
            return json["fields"]["summary"].str;
        catch (JSONException)
            return "";
    }
}
