# Messages App

A Rails application that sends messages to users at appropriate times, including birthday messages at 9am in their local timezone. The application is designed to be timezone-aware and includes a robust message delivery system with retry mechanisms.

## Requirements

- Ruby 3.1.4
- Rails 7.1.3
- PostgreSQL
- Redis (for Sidekiq)

## Setup

1. Clone the repository
2. Install dependencies:
   ```
   bundle install
   ```
3. Set up the database:
   ```
   rails db:create db:migrate
   ```
4. Set up environment variables:
   - `REDIS_URL`: URL for Redis (default: `redis://localhost:6379/0`)
   - `HOOKBIN_ENDPOINT`: URL for the Hookbin endpoint (create one at https://hookbin.com/)

## Running the Application

1. Start Redis:
   ```
   redis-server
   ```
2. Start Sidekiq:
   ```
   bundle exec sidekiq
   ```
3. Start the Rails server:
   ```
   rails server
   ```

## API Endpoints

### Create a User
```
POST /api/v1/users
```
Request body:
```json
{
  "user": {
    "first_name": "John",
    "last_name": "Doe",
    "birthdate": "1990-01-01",
    "location": "New York",
    "timezone": "America/New_York"
  }
}
```

### Update a User
```
PUT /api/v1/users/:id
```
Request body:
```json
{
  "user": {
    "first_name": "Jane",
    "last_name": "Smith",
    "birthdate": "1990-01-01",
    "location": "Los Angeles",
    "timezone": "America/Los_Angeles"
  }
}
```

### Delete a User
```
DELETE /api/v1/users/:id
```

## Architecture

The application is designed with a modular architecture that supports different message types and robust message delivery:

1. **Message Model**:
   - Central model handling various message types using the `message_type` field
   - Supports message statuses: pending, sent, failed
   - Includes retry mechanism with configurable max retries
   - Uses Enumerize gem for type-safe enums

2. **MessageSenderService**:
   - Service-based architecture for sending different types of messages
   - Implements strategy pattern for message type handling
   - Includes error handling and retry logic
   - Logs message delivery attempts and failures

3. **Background Jobs**:
   - Sidekiq jobs for asynchronous message processing
   - Distributed locking to prevent race conditions
   - Recovery mechanism for failed message deliveries

4. **User Model**:
   - Timezone-aware birthday message creation
   - Automatic timezone validation
   - Methods for checking birthday and message sending conditions

## Message Types

Currently supported message types:
- **Birthday Messages**: Sent to users on their birthday at 9am in their timezone

## Message Status and Retry Mechanism

Messages can have the following statuses:
- `pending`: Initial state, waiting to be sent
- `sent`: Successfully delivered
- `failed`: Failed to deliver after max retries

The system includes a retry mechanism:
- Messages are retried up to 5 times by default
- Retry count is tracked per message
- Failed messages are marked after max retries are reached
- The `SendPendingMessagesJob` serves as a recovery mechanism

## How It Works

1. The `BirthdayCheckJob` runs every hour and checks for users who:
   - Have a birthday today in their timezone
   - Are in a timezone where it's 9am
   - Don't already have a birthday message for today

2. When conditions are met, a pending birthday message is created with:
   - Message type set to birthday
   - Initial status of pending
   - Retry count of 0

3. The `SendPendingMessagesJob` runs every day and:
   - Finds all pending messages
   - Uses the `MessageSenderService` to send each message

4. The `MessageSenderService`:
   - Determines the appropriate sending strategy based on message type
   - Makes HTTP requests to the configured endpoint
   - Handles success and failure cases
   - Updates message status and retry count

## Adding New Message Types

To add a new message type:

1. Add the new type to the `message_type` enumeration in the `Message` model:
   ```ruby
   enumerize :message_type, in: [:birthday, :new_type], default: :birthday
   ```

2. Add a method in the `MessageSenderService` to handle sending the new message type:
   ```ruby
   def send_new_type_message
     # Implementation for sending the new message type
   end
   ```

3. Create any additional jobs or user methods needed to create messages of the new type

## Testing

The application includes a comprehensive test suite:

1. **Model Tests**:
   - Validations and associations
   - Enumerized attributes
   - Business logic methods
   - Timezone handling

2. **Controller Tests**:
   - API endpoint functionality
   - Parameter validation
   - Response status codes
   - Error handling

3. **Job Tests**:
   - Background job functionality
   - Distributed locking
   - Message creation and sending
   - Error handling and retries

4. **Service Tests**:
   - Message sending strategies
   - Error handling
   - Status updates
   - Retry mechanism

Run the test suite:
```
bundle exec rspec
```

## Sidekiq Web UI

The Sidekiq Web UI is available at `/sidekiq` for monitoring jobs and message processing.
