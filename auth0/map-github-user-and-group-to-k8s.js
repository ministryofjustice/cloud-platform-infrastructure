function (user, context, callback) {
    context.samlConfiguration.mappings = {
        };
    callback(null, user, context);
}
