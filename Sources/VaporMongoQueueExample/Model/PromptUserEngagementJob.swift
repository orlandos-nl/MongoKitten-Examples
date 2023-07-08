import Meow
import Vapor
import MongoQueue
import VaporSMTPKit
import SMTPKitten

struct PromptUserEngagementJob: RecurringTask {
    // The date this task should be executed at earliest
    // We default to one week from 'now'
    var initialTaskExecutionDate: Date {
        Date().addingTimeInterval(3600 * 24 * 7)
    }

    // We can use any execution context. This context is provided on registration, and the job can have access to it to do 'the work'
    // For example, if your job sends email, pass it a handle to the email client
    typealias ExecutionContext = Application

    // Stored properties will be written into the database
    let subject: Reference<User>

    // Ensures only one user engagement prompt exists per user
    var uniqueTaskKey: String { subject.description }

    // The amount of time we expect this task to take if it's very slow
    // This is optional, and has a sensible default. Note; it will not be the task's actual deadline.
    // Instead, the task will be killed if worker executing this task goes offline unexpectedly
    // There's a mechanism in MongoQueue to detect a stale or dead task worker
    var maxTaskDuration: TimeInterval { 60 }
    
    // This job has a low priority. Some other jobs may be done first if there's a contest for job queue time
    var priority: TaskPriority { .lower }

    // Execute the task. In our case, we check their last login date
    func execute(withContext context: ExecutionContext) async throws {
        let user = try await subject.resolve(in: context.meow)

        guard Date().timeIntervalSince(user.lastLogin) > 3600 * 24 * 7 else {
            // User was active recently, nothing to do
            return
        }

        // User wasn't active the last week, let's mail 'em!
        try await context.sendMail(
            Mail(
                from: "joannis@unbeatable.software",
                to: [
                    "you@example.com"
                ],
                subject: "Please return to our app!",
                contentType: .plain,
                text: "We'll give you extra cookies next time!"
            ),
            withCredentials: .default
        ).get()
    }

    // When to send the next reminder to the user
    // If `nil` is returned, this job will never run again
    func getNextRecurringTaskDate(_ context: ExecutionContext) async throws -> Date? {
        // Let's try again next week
        return Date().addingTimeInterval(3600 * 24 * 7)
    }

    // If we failed to run the job for whatever reason (SMTP issue, database issue or otherwise)
    func onExecutionFailure(failureContext: QueuedTaskFailure<ExecutionContext>) async throws -> TaskExecutionFailureAction {
        // Retry in 1 hour, `nil` for maxAttempts means we never stop retrying
        .retryAfter(3600, maxAttempts: nil)
    }
}

