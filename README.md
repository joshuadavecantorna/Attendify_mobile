# Attendify

A Laravel-based application for attendance management.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/joshuadavecantorna/Attendify_2.0.git
   cd attendify_v2
   ```

2. Install PHP dependencies:
   ```bash
   composer install
   ```

3. Install Node.js dependencies:
   ```bash
   npm install
   ```

4. Copy the environment file and configure it:
   ```bash
   cp .env.example .env
   # Edit .env with your database and other settings
   ```

5. Generate application key:
   ```bash
   php artisan key:generate
   ```

6. Run database migrations:
   ```bash
   php artisan migrate
   ```

7. Build assets:
   ```bash
   npm run build
   ```

8. Start the development server:
   ```bash
   php artisan serve
   ```

## Usage

- Access the application at `http://localhost:8000`
- For development with hot reloading:
  ```bash
  npm run dev
  ```

## Contributing

1. Create a new branch for your feature:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit:
   ```bash
   git add .
   git commit -m "Add your feature"
   ```

3. Push to your branch:
   ```bash
   git push origin feature/your-feature-name
   ```

4. Create a pull request on GitHub.


## Run NGROK and update N8N after device restart

1. Run in terminal:
   ```bash
   ngrok http https://attendify_2.0.test --host-header=rewrite
   ```

2. Copy URL and update .env

3. Update N8N URL in HTTP Request node:
   ```bash
   https://wedgier-earthlier-maliyah.ngrok-free.dev/api/n8n/schedules/today
   ```
   Don't forget to add (/api/n8n/schedules/today) at the end of the URL
