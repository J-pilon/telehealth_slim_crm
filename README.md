# Telehealth CRM

A minimal CRM skeleton built with Rails 7, designed for healthcare providers to manage patients, messages, and tasks with real-time updates using Hotwire.

## Features

- **User Authentication** - Devise-based login with admin/patient roles
- **Public Patient Registration** - Self-service patient onboarding with health questionnaire
- **Patient Management** - Complete CRUD operations with search and filtering
- **Message Threads** - Real-time messaging between staff and patients
- **Task Management** - Shared task queue with completion tracking
- **Real-time Updates** - Hotwire Turbo Streams for seamless UX
- **Responsive Design** - Tailwind CSS for modern, mobile-friendly interface
- **Background Jobs** - Sidekiq for email notifications
- **Comprehensive Testing** - RSpec with 341+ tests including feature tests
- **CI/CD Pipeline** - GitHub Actions with automated testing and security checks

## Authentication & User Roles

### Patient Registration
- Patients can self-register through the sign-up page
- All registrations default to the 'patient' role
- Upon registration, a patient profile is automatically created

### Admin Access
- Admins are invited by existing admins
- Admin users cannot be created through public registration
- Future consideration: Implement `devise_invitable` gem for formal invitation workflow

### Default Credentials (Development)
- Admin: admin@example.com / password123
- Patient: patient@example.com / password123

## Tech Stack

- **Ruby** 3.3.0
- **Rails** 7.2.2.2
- **PostgreSQL** 15+
- **Redis** 7+
- **Tailwind CSS** 2.0
- **Hotwire** (Turbo + Stimulus)
- **Sidekiq** 7.0
- **RSpec** 6.0
- **Devise** 4.9
- **Pundit** 2.3

## Prerequisites

Before you begin, ensure you have the following installed:

- **Ruby** 3.3.0 (recommended: use [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io/))
- **Rails** 7.2.2.2
- **PostgreSQL** 15+
- **Redis** 7+
- **Node.js** 18+ (for Tailwind CSS compilation)
- **Yarn** (for package management)

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd telehealth_crm
bundle install
yarn install
```

### 2. Environment Configuration

Copy the environment template and configure your settings:

```bash
cp .env.example .env
```

Edit `.env` with your database and Redis credentials:

```bash
# Database
DATABASE_URL=postgres://username:password@localhost:5432/telehealth_crm_development

# Redis
REDIS_URL=redis://localhost:6379/0

# Rails
SECRET_KEY_BASE=your_secret_key_here
```

### 3. Database Setup

```bash
# Create and migrate database
rails db:create
rails db:migrate

# Load seed data (creates admin users, patients, messages, and tasks)
rails db:seed
```

### 4. Start the Application

In separate terminal windows:

```bash
# Terminal 1: Rails server
rails server

# Terminal 2: Sidekiq worker
bundle exec sidekiq

# Terminal 3: Tailwind CSS watcher (optional, for development)
rails tailwindcss:watch
```

Or use the provided Procfile:

```bash
# Install foreman if you don't have it
gem install foreman

# Start all services
foreman start -f Procfile.dev
```

### 5. Access the Application

Visit [http://localhost:3000](http://localhost:3000)

## Default Login Credentials

After running `rails db:seed`, you can log in with:

### Admin User
- **Email**: admin@telehealth-crm.com
- **Password**: password123

### Patient User
- **Email**: Check the console output after seeding for a sample patient email
- **Password**: password123

## Application Flow

### Admin Workflow
1. **Dashboard** - View statistics and recent activity
2. **Create Patient** - Add new patient records
3. **Message Thread** - Communicate with patients
4. **Task Management** - Create and manage tasks
5. **Mark Complete** - Update task status

### Patient Workflow
1. **Login** - Access patient portal
2. **View Messages** - See communication history
3. **View Tasks** - Check assigned tasks
4. **Send Messages** - Communicate with staff

## Development

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/
bundle exec rspec spec/features/

# Run with coverage
COVERAGE=true bundle exec rspec
```

### Code Quality

```bash
# Lint Ruby code
bundle exec rubocop

# Lint ERB templates
bundle exec erb_lint --lint-all

# Security scan
bundle exec brakeman

# Fix auto-correctable issues
bundle exec rubocop -A
bundle exec erb_lint --lint-all --autocorrect
```

### Database Management

```bash
# Reset database with fresh seed data
bin/reset_db

# Create migration
rails generate migration AddFieldToModel field:type

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback
```

## Project Structure

```
app/
├── controllers/          # Rails controllers
│   ├── dashboard_controller.rb
│   ├── patients_controller.rb
│   ├── messages_controller.rb
│   └── tasks_controller.rb
├── models/              # ActiveRecord models
│   ├── user.rb
│   ├── patient.rb
│   ├── message.rb
│   └── task.rb
├── policies/            # Pundit authorization
│   ├── application_policy.rb
│   ├── patient_policy.rb
│   ├── message_policy.rb
│   └── task_policy.rb
├── views/               # ERB templates
│   ├── layouts/
│   ├── dashboard/
│   ├── patients/
│   ├── messages/
│   └── tasks/
├── javascript/          # Stimulus controllers
│   └── controllers/
├── jobs/                # Background jobs
│   ├── welcome_email_job.rb
│   └── task_reminder_job.rb
└── mailers/             # Email templates
    ├── patient_mailer.rb
    └── admin_mailer.rb

spec/                    # RSpec tests
├── models/
├── features/
├── controllers/
├── policies/
└── factories/

config/
├── database.yml
├── sidekiq.yml
└── routes.rb

.github/workflows/       # CI/CD pipeline
└── ci.yml
```

## API Endpoints

### Authentication
- `GET /users/sign_in` - Login page
- `POST /users/sign_in` - Login
- `DELETE /users/sign_out` - Logout

### Public Registration
- `GET /apply` - Public patient registration form
- `POST /apply` - Submit patient registration
- `GET /apply/success` - Registration confirmation page

### Patients
- `GET /patients` - List all patients
- `GET /patients/:id` - Show patient details
- `GET /patients/new` - New patient form
- `POST /patients` - Create patient
- `GET /patients/:id/edit` - Edit patient form
- `PATCH /patients/:id` - Update patient
- `DELETE /patients/:id` - Delete patient
- `GET /patients/search` - Search patients (JSON)

### Messages
- `GET /patients/:patient_id/messages` - Patient message thread
- `POST /patients/:patient_id/messages` - Send message
- `GET /patients/:patient_id/messages/:id` - Show message
- `GET /patients/:patient_id/messages/:id/edit` - Edit message
- `PATCH /patients/:patient_id/messages/:id` - Update message
- `DELETE /patients/:patient_id/messages/:id` - Delete message

### Tasks
- `GET /tasks` - Task queue
- `GET /tasks/:id` - Show task
- `GET /tasks/new` - New task form
- `POST /tasks` - Create task
- `GET /tasks/:id/edit` - Edit task
- `PATCH /tasks/:id` - Update task
- `DELETE /tasks/:id` - Delete task
- `PATCH /tasks/:id/complete` - Mark task complete
- `PATCH /tasks/:id/reopen` - Reopen task

## Background Jobs

### WelcomeEmailJob
Sends welcome email to new patients when they're created.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgres://localhost:5432/telehealth_crm_development` |
| `REDIS_URL` | Redis connection string | `redis://localhost:6379/0` |
| `SECRET_KEY_BASE` | Rails secret key | Generated automatically |
| `RAILS_ENV` | Rails environment | `development` |

### Sidekiq Configuration

Sidekiq is configured to run on Redis with the following queues:
- `default` - General background jobs
- `mailers` - Email sending jobs

Access the Sidekiq web UI at `/sidekiq` (admin only).

## Deployment

### Production Considerations

1. **Environment Variables** - Set all required environment variables
2. **Database** - Use a production PostgreSQL instance
3. **Redis** - Use a production Redis instance
4. **Background Jobs** - Ensure Sidekiq is running
5. **Asset Compilation** - Precompile assets for production
6. **Security** - Use HTTPS and secure session storage

### Docker Support

A `Dockerfile` is included for containerized deployment:

```bash
# Build image
docker build -t telehealth-crm .

# Run container
docker run -p 3000:3000 telehealth-crm
```

## Testing

The application includes comprehensive test coverage:

- **341+ RSpec tests** including model, controller, and feature tests
- **FactoryBot** for test data generation
- **Capybara** for system testing
- **Pundit matchers** for authorization testing

### Test Categories

- **Model Tests** - Validations, associations, scopes
- **Controller Tests** - HTTP responses, authorization
- **Feature Tests** - End-to-end user workflows
- **Policy Tests** - Authorization rules
- **Golden Path Test** - Complete user journey

## Changelog

### v1.0.0
- Initial release
- Complete CRM functionality
- Real-time messaging and task management
- Comprehensive test suite
- CI/CD pipeline