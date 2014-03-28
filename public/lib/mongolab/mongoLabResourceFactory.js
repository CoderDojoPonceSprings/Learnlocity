function mongoLabResourceFactory(resourceService, resourcePath, resourceName, apiKey) {
    var resource = resourceService(resourcePath + '/' + resourceName + '/:id', {
        apiKey: apiKey
    }, {
        update: {
            method: 'PUT'
        }
    });

    resource.prototype.update = function (cb) {
        return resource.update({
                id: this._id.$oid
            },
            angular.extend({}, this, {
                _id: undefined
            }), cb);
    };

    resource.prototype.updateSafe = function (patch, cb) {
        resource.get({id:this._id.$oid}, function(obj) {
            for(var prop in patch) {
                obj[prop] = patch[prop];
            }
            obj.update(cb);
        });
    };

    resource.prototype.destroy = function (cb) {
        return resource.remove({
            id: this._id.$oid
        }, cb);
    };

    return resource;
}