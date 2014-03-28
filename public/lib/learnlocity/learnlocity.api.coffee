(->
	dbUrl = "https://api.mongolab.com/api/1/databases/coderdojochat/collections"
	apiKey = "bWK-cL1WKkJF6yyunAhSjhszvkkTTOlM"
	apiModule = angular.module("learnlocity.api", ["ngResource"])

	collection = (className) ->
		mongoCollectionName = className.toLowerCase()
		apiModule.factory className, ($resource) ->
			return mongoLabResourceFactory $resource, dbUrl, mongoCollectionName, apiKey

	collection "User"
	collection "Snippet"
	collection "Favorite"
	collection "Tribe"
)()