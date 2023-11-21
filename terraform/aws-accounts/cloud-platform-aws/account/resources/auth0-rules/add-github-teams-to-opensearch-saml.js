function(user, context, callback) {
  var request = require("request");
  var modsecClientId = context.clientID === configuration.OPENSEARCH_APP_CLIENT_ID == context.connection === "github"
  var appClientId = context.clientID === configuration.OPENSEARCH_APP_CLIENT_ID_APP_LOGS == context.connection === "github"

  if (modsecClientId || appClientId) {
    // Get user"s Github profile and API access key
    var github_identity = user.identities.find(id => id.connection === "github");

    // Get list of user"s Github teams
    var teams_req = {
      url: "https://api.github.com/user/teams",
      headers: {
        "Authorization": "token " + github_identity.access_token,
        "User-Agent": "request"
      }
    };

    // make the request to github
    request(teams_req, function(err, resp, body) {
      if (resp.statusCode !== 200) {
        return callback(new Error("Error retrieving teams from Github: " + body || err));
      }

      var git_teams = JSON.parse(body).map(function(team) {
        if (team.organization.login === "ministryofjustice") {
          return team.slug;
        }
      });

      user.GithubTeam = git_teams;

      // map the teams to saml
      context.samlConfiguration.mappings = {
        "http://schemas.xmlsoap.org/claims/Group": "GithubTeam"
      };

      return callback(null, user, context);
    });
  } else {

    return callback(null, user, context);
  }
}
