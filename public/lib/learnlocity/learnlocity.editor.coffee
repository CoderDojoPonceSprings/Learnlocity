(->
	mod = angular.module('learnlocity.editor', ['ui.ace', 'ui.bootstrap'])

	mod.controller 'questController', ($scope) ->
		console.log('We started the quest')
		$scope.questVisible = false
		$scope.stepVisible = true	
		$scope.teamVisible	= true

	mod.controller 'editorController', ($scope, $timeout, $window, $rootScope) ->
		$scope.displays =
			html: true
			css: true
			js: true
			preview: true

		$scope.update = 
			whenTyping: true
			previewBelow: false

		getNumDisplaysVisible = ->
			numTurnedOn = 0
			for k,v of $scope.displays
				if v == true then numTurnedOn++

			if $scope.displays.preview and $scope.update.previewBelow 
				numTurnedOn--
		
			numTurnedOn
		
		$scope.getEditorsClass = ->
			numTurnedOn = getNumDisplaysVisible()
			'col-md-' + (12 / numTurnedOn)


		$scope.getPreviewClass = ->
			numTurnedOn = getNumDisplaysVisible()
			if not $scope.update.previewBelow 
				'col-md-' + (12 / numTurnedOn)
			else
				'col-md-12'

		jsEditor = null
		htmlEditor = null
		cssEditor = null
		editors =
			html: null
			css: null
			js: null

		$scope.editorsToLoadCount = 3

		updateEditorHeights = ->
			baseLineOffsetTop = $('#step').offset().top
			$('.editor').resizable()
			$('.editor, .ace_wrapper, .preview').each ->
				newHeight = $window.document.body.clientHeight - baseLineOffsetTop - 20
				$(@).height(newHeight)
			for key, editor of editors
				editor.resize()

		angular.element($window).bind 'resize', updateEditorHeights

		configureEditor = (editor) ->
			editor.setFontSize("14px")
			session = editor.getSession()
			session.on("change", editorContentChanged)
			$scope.editorsToLoadCount--

		editorContentChanged = ->
			if $scope.displays.preview && $scope.update.whenTyping then $scope.preview()

		$scope.htmlLoaded = (editor) ->
			htmlEditor = editor
			editors["html"] = editor
			configureEditor editor

		$scope.cssLoaded = (editor) ->
			cssEditor = editor
			editors["css"] = editor
			configureEditor editor

		$scope.jsLoaded = (editor) ->
			jsEditor = editor
			editors["js"] = editor
			configureEditor editor

		$scope.previewToggle = ->
			$scope.displays.preview = !$scope.displays.preview
			if $scope.displays.preview
				$scope.preview()

		$scope.preview = ->
			script = document.createElement("script")
			script.type = "text/javascript"	    
			script.text = jsEditor.getSession().getValue()

			head = $("<head></head>")
			head.append "<title>CoderDojo Ponce Springs</title>"
			head.append $(script)

			style = $("<style type='text/css'></style>")
			style.append cssEditor.getSession().getValue()
			head.append style

			body = $("<body></body>")
			body.append htmlEditor.getSession().getValue()

			html = $("<html></html>")
			html.append head
			html.append body

			userName = $scope.code.userName

			$("#" + userName).each ->
				doc = @contentWindow.document
				doc.open()
				doc.write "<html>" + html.html() + "</html>"
				doc.close()		

		# TODO: this is a little bit hacktastic:
		$scope.$watch 'editorsToLoadCount', ->
			if $scope.editorsToLoadCount <= 0
				$timeout ->
					if $scope.previewOnLoad
						$scope.preview()
					updateEditorHeights()
				, 250

		$scope.save = ->
			userName = $rootScope.gitHubUserName
			repo = $rootScope.github.getRepo(userName, 'SaveTBL')

			content = htmlEditor.getSession().getValue()
			repo.write 'master', 'index.html', content, 'Commit from Learnlocity!', (err) ->
				if err 
					console.log 'Error creating file in GitHub:' + err 
				else
					content = cssEditor.getSession().getValue()
					repo.write 'master', 'index.css', content, 'Commit from Learnlocity!', (err) ->
						if err 
							console.log 'Error creating file in GitHub:' + err 
						else
							content = jsEditor.getSession().getValue()					
							repo.write 'master', 'index.js', content, 'Commit from Learnlocity!', (err) ->
							if err 
								console.log 'Error creating file in GitHub:' + err
)()