function (user, context, callback) {
  var request = require('request');

  // Apply to 'github' connections only
  if (context.connection === 'github') {
    // Get user's Github profile and API access key
    var github_identity = _.find(user.identities, { connection: 'github' });

    // Get list of user's Github teams
    var teams_req = {
      url: 'https://api.github.com/user/teams?per_page=100',
      headers: {
        'Authorization': 'token ' + github_identity.access_token,
        'User-Agent': 'request'
      }
    };

    request(teams_req, function(err, resp, body) {
      if (resp.statusCode !== 200) {
        return callback(new Error('Error retrieving teams from github: ' + body || err));
      }

      // Construct list of user's Github teams
      // The team slug is used, to normalise whitespace, capitalisation etc.
      var git_teams = JSON.parse(body).map(function(team) {
        if (team.organization.login === "ministryofjustice") {
          return "github:" + team.slug;
        }
      });

      // Add team list to the user's JWT as a custom claim
      //
      // Custom OIDC claims should be prefixed with a unique value
      // to prevent clashes with claims from other sources.
      // Common practice is to use a URL
      context.idToken[configuration.K8S_OIDC_GROUP_CLAIM_DOMAIN] = git_teams;

      return callback(null, user, context);
    });
  } else {
    return callback(null, user, context);
  }
}
