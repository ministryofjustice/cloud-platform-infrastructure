function (user, context, callback) {
  var request = require('request');

  var github_org_whitelist = ['ministryofjustice'];

  // Apply to 'github' connections only
  if(context.connection === 'github'){
    // Get user's Github profile info (an Auth0 user can have multiple 
    // connected accounts - Google, Facebook etc)
    //
    // Github user profile will also contain a Github API access token
    // which we can use to look up teams etc.
    var github_identity = _.find(user.identities, { connection: 'github' });

    // Get list of Github orgs for the user
    var orgs_req = {
      url: 'https://api.github.com/user/orgs',
      headers: {
          'Authorization': 'token ' + github_identity.access_token,
          'User-Agent': 'request'
      }
    };

    request(orgs_req, function (err, resp, body) {
      if (resp.statusCode !== 200) {
        return callback(new Error('Error retrieving orgs from github: ' + body || err));
      }

      // Construct list of Github org names
      var user_orgs = JSON.parse(body).map(function(org){
        return org.login;
      });

      // Check if user is in a whitelisted org, return HTTP 401 if not
      var authorized = github_org_whitelist.some(function(org){
        return user_orgs.indexOf(org) !== -1;
      });

      if (!authorized) {
        return callback(new UnauthorizedError('Access denied.'));
      }

      return callback(null, user, context);
    });

  } else {
    // Callback must always be returned
    return callback(null, user, context);
  }
}
