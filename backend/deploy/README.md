# Backend Deployment Guide

This guide explains how to set up automated deployment for the Todo Backend API using GitHub Actions with PM2 process management.

## Server Setup

### Install Dependencies

1. **Install Node.js and PM2:**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   sudo npm install -g pm2
   ```

2. **Install PostgreSQL:**
   ```bash
   sudo apt update
   sudo apt install postgresql postgresql-contrib
   ```

3. **Set up PM2 to start on boot:**
   ```bash
   pm2 startup
   # Follow the instructions shown
   ```

4. **Create application directory:**
   ```bash
   sudo mkdir -p /var/www/todo-app
   sudo chown -R $USER:$USER /var/www/todo-app
   ```

## GitHub Secrets Configuration

Configure the following secrets in your GitHub repository settings:

### Required Secrets

- **`SERVER_HOST`** - Your server's IP address or domain name
- **`SERVER_USERNAME`** - SSH username for your server
- **`SERVER_SSH_KEY`** - Private SSH key for authentication (contents of your private key file)
- **`DATABASE_URL`** - PostgreSQL connection string (e.g., `postgres://username:password@localhost:5432/todo_db`)
- **`JWT_SECRET`** - Secret key for JWT token signing (generate a secure random string)

### Optional Secrets

- **`PORT`** - Port number for the API (defaults to 8080)

### Example DATABASE_URL formats:

```bash
# Local PostgreSQL
postgres://username:password@localhost:5432/todo_db

# Remote PostgreSQL
postgres://username:password@your-db-host:5432/todo_db

# PostgreSQL with SSL
postgres://username:password@your-db-host:5432/todo_db?sslmode=require
```

## Database Setup

Create the database on your server:

```bash
sudo -u postgres createdb todo_db
sudo -u postgres psql -c "CREATE USER todo_user WITH PASSWORD 'your_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE todo_db TO todo_user;"
```

## Deployment Process

1. **Push to main branch** - The workflow will trigger automatically
2. **Build** - Go application is built for Linux
3. **Deploy** - Binary and environment file are copied to server
4. **Restart** - PM2 restarts the service with the new version

## Troubleshooting

### Check PM2 status:
```bash
pm2 status
pm2 logs todo-backend
pm2 restart todo-backend
```

### View detailed logs:
```bash
pm2 logs todo-backend --lines 100
```

### Manual deployment:
```bash
# Build locally
cd backend
make prod-build

# Copy to server
scp bin/server user@your-server:/var/www/todo-app/bin/
```

### Restart PM2 manually:
```bash
cd /var/www/todo-app
pm2 delete todo-backend
pm2 start bin/server --name todo-backend
pm2 save
```

## Security Notes

- Ensure your server firewall only allows necessary ports (22 for SSH, 80/443 for HTTP/HTTPS, and your API port)
- Use strong passwords for database and SSH keys
- Consider using fail2ban for SSH protection
- Keep your server and dependencies updated regularly
- Use a reverse proxy (nginx) to handle HTTPS and static files

## Production Tips

- Set up a reverse proxy with nginx:
  ```nginx
  server {
      listen 80;
      server_name your-domain.com;
      
      location / {
          proxy_pass http://localhost:8080;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
      }
  }
  ```

- Monitor with PM2:
  ```bash
  pm2 install pm2-logrotate
  pm2 set pm2-logrotate:max_size 10M
  pm2 set pm2-logrotate:retain 7
  ``` 