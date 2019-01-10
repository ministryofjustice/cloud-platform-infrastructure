var https = require('https');
var util = require('util');
var url = require('url');

var swh = url.parse(process.env.SLACK_WEBHOOK);

function tryParseJSON (jsonString){
    try {
        var o = JSON.parse(jsonString);

        // Handle non-exception-throwing cases:
        // Neither JSON.parse(false) or JSON.parse(1234) throw errors, hence the type-checking,
        // but... JSON.parse(null) returns 'null', and typeof null === "object",
        // so we must check for that, too.
        if (o && typeof o === "object" && o !== null) {
            return o;
        }
    }
    catch (e) { }

    return false;
}

exports.handler = function(event, context) {
    console.log(JSON.stringify(event, null, 2));
    console.log('From SNS:', event.Records[0].Sns.Message);

    var postData = {
        "username": "AWSlack",
        "text": "*" + event.Records[0].Sns.Subject + "*",
        "icon_emoji": ":sob:"
    };
    if (process.env.SLACK_CHANNEL != "") {
      postData["channel"] = process.env.SLACK_CHANNEL;
    }

    var message = event.Records[0].Sns.Message;
    var severity = "good";

    var dangerMessages = [
        " but with errors",
        " to RED",
        "ALARM",
        "ERROR",
        "During an aborted deployment",
        "Failed to deploy application",
        "Failed to deploy configuration",
        "has a dependent object",
        "is not authorized to perform",
        "Pending to Degraded",
        "Stack deletion failed",
        "Unsuccessful command execution",
        "You do not have permission",
        "Your quota allows for 0 more running instance"];

    var warningMessages = [
        " aborted operation.",
        " to YELLOW",
        "INSUFFICIENT",
        "WARNING",
        "Adding instance ",
        "Degraded to Info",
        "Deleting SNS topic",
        "is currently running under desired capacity",
        "Ok to Info",
        "Ok to Warning",
        "Pending Initialization",
        "Removed instance ",
        "Rollback of environment"
        ];

    for(var dangerMessagesItem in dangerMessages) {
        if (message.indexOf(dangerMessages[dangerMessagesItem]) != -1) {
            severity = "danger";
            break;
        }
    }

    // Only check for warning messages if necessary
    if (severity == "good") {
        for(var warningMessagesItem in warningMessages) {
            if (message.indexOf(warningMessages[warningMessagesItem]) != -1) {
                severity = "warning";
                break;
            }
        }
    }

    // If this is a report of an alam being 'ok' then overwrite the bad severity
    if( message.indexOf('\"NewStateValue\":\"OK\"') != -1 ){
        severity = "good";
    }

    postData.attachments = [
        {
            "color": severity,
            "text": message
        }
    ];

    var messageJSON = tryParseJSON(message);
    if (messageJSON){
        message = "";
        for(var key in messageJSON ){
            message += "*"+key+"*: "+messageJSON[key]+"\n";
        }
        postData.attachments = [
            {
                "color": severity,
                "text": message,
                "mrkdwn_in": [
                    "text"
                ]
            }
        ];
    }

    var options = {
        method: 'POST',
        hostname: swh.host,
        port: 443,
        path: swh.pathname
    };

    var req = https.request(options, function(res) {
      res.setEncoding('utf8');
      res.on('data', function (chunk) {
        context.done(null);
      });
    });

    req.on('error', function(e) {
      console.log('problem with request: ' + e.message);
    });

    req.write(util.format("%j", postData));
    req.end();
};
