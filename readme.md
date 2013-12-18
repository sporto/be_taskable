BeTaskable
==========

[![Build Status](https://travis-ci.org/sporto/be_taskable.png?branch=master)](https://travis-ci.org/sporto/be_taskable)

BeTaskable is a small framework for creating and maintaining tasks / chores / assignments. Meaning something that someone has to do.

Concepts
--------

### Taskable

Any object that needs action, e.g. a document. The taskable can have different actions e.g. publish, authorise

### Assignee

Object that has to do the task. E.g. user

### Task

An object representing an action that needs to be done for a particular taskable.
e.g. Publish document #29

A task can have many assignees (See Task Assignments).

### Task Assignment

An object linking a task and a assignee.
e.g. User #80 can publish document #29

### Resolver

An object linked to a taskable that has the business logic for your particular application.

Usage
-----

### Taskable Model

Make a model taskable

	class Taskable < ActiveRecord::Base
		be_taskable
	end

### Task Resolver

A resolver is a class that should provide the business logic for each particular task.
The resolver name is composed of the following parts:

- Name of the taskable model e.g. Document
- + the name of the action e.g. Publish
- + 'TaskResolver'

	class DocumentPublishTaskResolver < BeTaskable::TaskResolver
		
	end

A resolver object should provide the following methods:

	class DocumentPublishTaskResolver < BeTaskable::TaskResolver
		
		def consensus?(task)
			# This method should decide if the task is completed based on the assigments
			# return true or false

			# Some possible scenarios are:

			# any assignment is completed then return true
			# task.any_assignment_done?

			# the majority of assignments are completed then return true
			# task.majority_of_assignments_done?

			# all task are completed then return true
			# task.all_assignments_done?

			# use task.assignments to calculate consensus manually
		end

		def is_task_relevant?(task)
			true
		end

		def assignees_for_task(task)
			# Return a list of assignees for this particular task
		end

		def due_date_for_assignment(assignment)
			# called each time an assignment is created
			# return here when the assignment should be completed by
			# e.g. DateTime.now + two.weeks
			# return nil = no due date
		end

		def visible_date_for_assignment(assignment)
			# this sets the visible_at property on the assignment
			# this is useful if you don't want an assignment to be visible until some time in the future
		end

		def label_for_task(task)
			# return a label (name or description) for the task (if you need to show it on the ui)
			# get the taskable by calling task.taskable
		end

		def label_for_assigment(assignment)
			# return a label for the assignment
			# get the taskable by calling assignment.taskable
		end

		def url_for_assignment(assignment)
			# return a url where to go for the assigment
			# get the taskable by calling assignment.taskable
		end

		# hooks
		def on_creation(task)
			# called when a task is created
		end

		def on_completion(task)
			# will be called when a task is completed
		end

		def on_expiration(task)
			# will be called when a task is expired
		end

	end

Create a resolver class for each taskable/action combination.

### Creating a task

Given a taskable model, create a new task like this:

	task = document.create_task_for_action('publish')

This creates the task and the assignments. You don't assign assignees to a task manually, they are assigned by the resolver. 

Also there is a `create_or_refresh_task_for_action` method. This will reuse an existing task if present and is __not completed__ and __not expired__.

### Completing a task

After completing an action you will usually have the taskable in hand. Using the taskable you can find the task like so:

	task = taskable.last_task_for_action('publish') # will give you the last task
	task.complete_by(assignee)

You may complete the task by using:

	taskable.complete_task_for('publish', assignee)

When a task is completed several things will happen:

- Task will find the assignment for that particular assignee
- It will set the assignment as completed
- It will call the .consensus? method in the task resolver
- If consensus? returns true then it will set all the assignment to completed and the task as completed

You can check if a task is completed by doing:

	task.completed?

Other options:

	task.complete!
	# completes the task regardless for all assignees. Marks all the assignments as completed.

	taskable.complete_task_for_action('publish')
	# same as task.complete!

Task.refresh
------------

When task.refresh is called the following will happen:

- Mark all the current task assignments as 'unconfirmed'
- Find the list of assignees
- Find or create an assignment for each assignee
- Set those assignment to confirmed
- Delete all the assignments that are still left as 'unconfirmed'

This means that if the business rules change in your resolver or the assignees change (e.g. you have more users) then `task.refresh` will create and deleted assignments as needed.
`task.refresh` has no effect if the task is already completed. Also it won't delete assignments that are already completed.

Task.tally
----------

This checks if the task can be considered done, it uses the `consensus?` method in the resolver to decide this. If the task is done then all assignments will be marked as completed.

Task.audit
--------

Calls `task.refresh` and `task.tally` immediatelly.

This is useful for an audit of process that runs everyday to check the validity of the assignments in your application, e.g.

	BeTaskable::Task.find_each do |task|
		task.audit
	end

Task.expire
-----------

This sets the task as no longer valid, it expires all the assignments and calls the on_expiration method on the resolver

	task.expire

Label and url
-------------

When task.run is called task.label, assignment.label and assignment.url are generated (using the resolver) and stored in the database. They are re-generated each time task.run is called.
When you call task.label, assignment.label and assignment.url they will be retrieved from the cached attribute stored in the database.
If you want to use the no-cached version use task.label!, assignment.label! and assignment.url! these will ask the resolver directly.

Who did the task?
-----------------

To find out who did a particular task do the following:

	assignments = tasks.enacted_assignments # this are the assignments that were actually completed by their assignees
	assignees = assignments.map(&:assignee)

Task Assignment Scopes
---------------------

The following scopes are available for task assignments:

- completed
- uncompled
- visible
- expired
- unexpired
- overdue
- not_overdue
- current: which are uncompled + visible + unexpired + not_overdue

Assignee
---------
This is the object doing a task. e.g. User

Mixin in `be_tasker` into your model to access the BeTaskable methods:

	class User < ActiveRecord::Base
		be_tasker
	end

	user.task_assignments #=> array with all assignments
	user.task_assignments.current #=> array of current assignments

Testing (rspec)
-------

To stub a resolver do the following:

	resolver = DocumentAuthorizeTaskResolver.new

	# stub the taskable class
	Document.stub(:_task_resolver_for_action).and_return(resolver)

	# now you can stub the resolver
	resolver.stub(:assignees_for_task).and_return([user1, user2])

	document = Document.create
	document.create_task_for_action('authorize') # this will use the stubbed resolver

Generators
----------

A handy generator is provided for creating the necessary tables

	rails g be_taskable:migration

Also a genator for task resolvers is provided:

	rails g be_taskable:resolver document publish


Testing this Gem
----------------

	bundle
	rspec

Deploying
---------




License
-------

MIT





