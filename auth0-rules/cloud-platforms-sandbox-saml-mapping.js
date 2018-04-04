function (user, context, callback) {
    var request = require('request');
  
    var github_org_whitelist = ['ministryofjustice'];
  
    // Apply to 'github' connections only
    if(context.connection === 'github'){
      var github_identity = _.find(user.identities, { connection: 'github' });
  
      // Only allow members of whitelisted Github orgs
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
  
        var user_orgs = JSON.parse(body).map(function(org){
          return org.login;
        });
  
        var authorized = github_org_whitelist.some(function(org){
          return user_orgs.indexOf(org) !== -1;
        });
  
        if (!authorized) {
          return callback(new UnauthorizedError('Access denied.'));
        }
      });
  
      // Get user's Github team list
      var teams_req = {
        url: 'https://api.github.com/user/teams',
        headers: {
          'Authorization': 'token ' + github_identity.access_token,
          'User-Agent': 'request'
        }
      };
  
      request(teams_req, function (err, resp, body) {
        if (resp.statusCode !== 200) {
          return callback(new Error('Error retrieving teams from github: ' + body || err));
        }
  
        var idp_arn = "arn:aws:iam::926803513772:saml-provider/cloud-platforms-sandbox-auth0";
        var role_base_arn = "arn:aws:iam::926803513772:role/";
  
        user.awsRole = JSON.parse(body).map(function (team) {
          return role_base_arn + "test-github-" + team.slug + "," + idp_arn;
        });
  
        user.awsRoleSession = user.nickname;
      
        context.samlConfiguration.mappings = {
          'https://aws.amazon.com/SAML/Attributes/Role': 'awsRole',
          'https://aws.amazon.com/SAML/Attributes/RoleSessionName': 'awsRoleSession'
        };
  
        return callback(null, user, context);
      });
  
    } else {
      callback(null, user, context);
    }
  }
