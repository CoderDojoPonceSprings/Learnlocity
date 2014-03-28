(->	
	has_attr = (el, attr) ->
		at = el.attr(attr)
		return typeof at isnt 'undefined' and at isnt false	

	app = angular.module 'tutorializr', ['learnlocity']

	app.directive 'gitem', ["$http", ($http) ->
		restrict: 'E'
		template: "<div ng-bind-html-unsafe='content'></div>"
		replace: true
		scope:
			src: '@src'
		link: (scope, element, attrs) ->
			attrs.$observe 'src', (src) ->		
				$http.get(scope.src).success (content) ->
					scope.content = content
	]

	app.controller 'slidesController', ['$scope', ($scope) ->
		$scope.get_questions = (slide) ->
			questions = []
			slide.find('.questions').each ->
				$(@).find('.question').each ->			
					choices = []
					$(@).find('li').each ->
						item = $(@)
						choice = 
							text: item.html()
							description: item.attr('title')
							correct: has_attr item, 'data-correct'
							selected: false
						choices.push choice
					questions.push
						title: $(@).find('h1').text()
						choices: choices
			return questions

		$scope.slides = []
		$('#slides .slide').each ->
			@id = 'slide-' + ($scope.slides.length + 1)
			questions = $scope.get_questions $(@)
			questions.correct_count = 0
			$scope.slides.push 
				content: @
				questions: questions

		$scope.slide_has_prev = -> $scope.slide_position > 1
		$scope.slide_prev = -> $scope.slide_load $scope.slide_position - 1
		$scope.slide_has_next = -> $scope.slide_position < $scope.slides.length
		$scope.slide_next = -> $scope.slide_load $scope.slide_position + 1

		$scope.slide_header = $scope.slide_content = ''
		$scope.slide_load = (slide_number) ->
			slide_number = parseInt slide_number
			return if (slide_number < 1 or slide_number > $scope.slides.length)
			$scope.slide_position = slide_number
			$scope.resources_visible = false
			slide = $scope.slides[slide_number - 1]
			#slide_source = $('#slide-' + slide_number)
			slide_source = $(slide.content)
			$scope.slide_header = slide_source.attr('data-title')

			content = slide_source.find('.content')
			$scope.slide_content = if content.length > 0 then content else ''

			references = slide_source.find('.references')
			$scope.slide_resources = if references.length > 0 then references.html() else ''
			
			$scope.questions = slide.questions
			$scope.question_position = 0
			if $scope.questions.length > 0
				$scope.question = $scope.questions[0]

			$scope.loaded = true

		$scope.get_slide_active_class = (slide_num) ->
			return if slide_num is $scope.slide_position then 'active' else ''

		$scope.slide_load 1

		$scope.get_choice_class = (question, choice) ->
			if question.scored and choice.selected isnt true and choice.correct is false
				return 'dimmed'
			if question.scored and choice.selected is true and choice.correct is true
				return 'correct-selected'
			if question.scored and choice.correct is true
				return 'correct'
			if question.scored and choice.selected is true and choice.correct is false
				return 'incorrect'
			else
				return ''

		$scope.question_score = ->
			$scope.question.scored = true
			for choice in $scope.question.choices
				if choice.selected and choice.correct
					choice.answer_correct = true
					$scope.questions.correct_count++
				else 
					choice.answer_correct = false

		$scope.get_correct_answers_percentage = ->
			correct_count = $scope.questions.correct_count
			percentage = (correct_count / $scope.questions.length) * 100
			return parseInt percentage

		$scope.question_has_next = -> $scope.question_position < $scope.questions.length - 1

		$scope.question_next = ->
			if $scope.question_has_next()
				$scope.question_position++
				$scope.question = $scope.questions[$scope.question_position]
	]
)()	