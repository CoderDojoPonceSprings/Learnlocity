(-> 
  apiErrorHandle = (err) ->
    message = 'Encountered an unexpected error:\n\n' + JSON.stringify(err)    
    console.error message

  mod = angular.module('learnlocity.tribes', ['ui.bootstrap', 'learnlocity.api'])
  
  dialog = null

  dialogOptions =
    controller: 'createController'
    templateUrl: 'partials/learnlocity.tribes.create.html'
    backdrop: true
    keyboard: true
    backdropClick: true

  mod.controller 'tribeCreateController', ($rootScope, $scope, $dialog, Tribe) ->
    clearErrors = ->
      $scope.tribeNameTaken = false
    
    $scope.form =
      name: ''
      description: ''
      location: ''
      tags: ''

    $scope.showCreateTribeDialog = ->
      dialog = $dialog.dialog(dialogOptions)
      dialog.open().then (result) -> console.log result if result

    $scope.close = (result) ->
      dialog.close result

    $scope.create = ->
      clearErrors()
      Tribe.query({
        q: JSON.stringify({
          name:
            $regex: '^' + $scope.form.userName + '$'
            $options: 'i'
        })
      ), ((results) ->
        if results.length > 0
          tribe = results[0]
          $rootScope.userName = user.userName
          $rootScope.userLoggedIn = true
          dialog.close true
        else
          $scope.loginFailed = true
      ), apiErrorHandle

    $scope.register = ->
      clearErrors()
      User.query
        q: JSON.stringify(userName:
          $regex: '^' + $scope.form.userName + '$'
          $options: 'i'
        )
      , ((results) ->
        if results.length > 0
          $scope.userNameTaken = true
        else
          user =
            userName: $scope.form.userName
            password: $scope.form.password

          User.save user, ((newUser) ->
            $rootScope.userName = newUser.userName
            $rootScope.userLoggedIn = true
            dialog.close true
          ), apiErrorHandle
      ), apiErrorHandle
)()