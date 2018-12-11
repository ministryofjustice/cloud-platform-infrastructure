function (user, context, callback) {
  var request = require('request');
  var github_team_whitelist = ['webops'];
  if(context.connection === 'github'){
    var github_identity = _.find(user.identities, { connection: 'github' });
    var teams_req = {
      url: 'https://api.github.com/user/teams',
      headers: {
          'Authorization': 'token ' + github_identity.access_token,
          'User-Agent': 'request'
      }
    };
    request(teams_req, function (err, resp, body) {
      if (resp.statusCode !== 200) {
        return callback(new Error('Error retrieving orgs from github: ' + body || err));
      }
      var user_teams = JSON.parse(body).map(function (team) {
        return team.slug;
      });
      // Check if user is in a whitelisted team, return HTTP 401 if not
      var authorized = github_team_whitelist.some(function(team){
        return user_teams.indexOf(team) !== -1;
      });
      if (!authorized) {
        return callback(new UnauthorizedError('Access was denied.'));
      }
      return callback(null, user, context);
    });
  } else {
    return callback(null, user, context);
  }
}
