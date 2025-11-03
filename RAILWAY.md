# Railway Deployment Guide

This guide explains how to deploy Ghost CMS to Railway.

## Prerequisites

1. A Railway account ([railway.app](https://railway.app))
2. A MySQL database (Railway MySQL service or external)

## Setup Steps

### 1. Create Railway Project

1. Go to [Railway](https://railway.app) and create a new project
2. Click "New Project" → "Deploy from GitHub repo"
3. Select this repository
4. Add a MySQL service: Click "New" → "Database" → "MySQL"

### 2. Configure Environment Variables

Set the following environment variables in Railway for your Ghost service:

#### Required Variables

```bash
NODE_ENV=production

# Database Configuration
# Option 1: Use Railway's MySQL service variables (recommended)
database__connection__host=${{MySQL.MYSQLHOST}}
database__connection__user=${{MySQL.MYSQLUSER}}
database__connection__password=${{MySQL.MYSQLPASSWORD}}
database__connection__database=${{MySQL.MYSQLDATABASE}}
database__client=mysql

# Option 2: Or set manually if using external MySQL
# database__connection__host=your-mysql-host
# database__connection__user=your-mysql-user
# database__connection__password=your-mysql-password
# database__connection__database=your-database-name
# database__client=mysql

# Ghost URL (set after first deploy with your Railway domain)
url=https://your-app.railway.app
```

**Note**: Railway provides MySQL connection variables automatically. Use the variable reference syntax `${{MySQL.VARIABLE_NAME}}` to reference them.

#### Optional Variables

```bash
# Mail Configuration (if using email)
mail__transport=SMTP
mail__options__host=smtp.example.com
mail__options__port=587
mail__options__auth__user=your-smtp-user
mail__options__auth__pass=your-smtp-password
mail__options__secure=false
mail__options__requireTLS=true

# Redis (if using external Redis cache)
redis__host=your-redis-host
redis__port=6379
redis__password=your-redis-password
```

### 3. Deploy

1. Railway will automatically detect the `railway.json` file
2. It will build using `Dockerfile.production`
3. The entrypoint script (`railway-entrypoint.sh`) will:
   - Wait for database connection (with retries)
   - Run migrations automatically
   - Start Ghost

### 4. First-Time Setup

After first deployment:

1. Visit your Railway app URL (found in Railway dashboard)
2. You should see the Ghost setup wizard
3. Complete the setup:
   - Create your admin account
   - Set your site title and description
   - Configure your site settings

### 5. Update URL After Deployment

After Railway assigns your domain:

1. Go to your service settings in Railway
2. Copy your public domain (e.g., `your-app.railway.app`)
3. Update the `url` environment variable to match your domain
4. Redeploy or restart the service

## Environment Variable Reference

### Database Variables

When using Railway's MySQL service, you can reference these variables:

- `${{MySQL.MYSQLHOST}}` - MySQL host
- `${{MySQL.MYSQLUSER}}` - MySQL username  
- `${{MySQL.MYSQLPASSWORD}}` - MySQL password
- `${{MySQL.MYSQLDATABASE}}` - Database name
- `${{MySQL.MYSQLPORT}}` - MySQL port (usually 3306)

### Ghost Configuration

Ghost uses environment variables with double underscore notation:

- `database__connection__host` - Database host
- `database__connection__user` - Database user
- `database__connection__password` - Database password
- `database__connection__database` - Database name
- `database__client` - Database client (`mysql` or `sqlite3`)
- `url` - Your Ghost site URL (must match your Railway domain)

## Troubleshooting

### Build Fails

- **Check build logs in Railway**: Look for specific error messages
- **Build time**: First build may take 10-15 minutes due to monorepo complexity
- **Memory issues**: Railway provides adequate memory, but if builds fail, check the logs
- **Dependencies**: Ensure all package.json files are correctly structured

### Database Connection Errors

- **Verify environment variables**: Double-check variable names and values
- **Railway MySQL variables**: Ensure you're using the correct variable reference syntax
- **Network**: If using external MySQL, ensure it's accessible from Railway
- **Connection string**: For Railway MySQL, use the internal hostname provided by Railway

### Migrations Fail

- **Check database permissions**: Ensure the MySQL user has CREATE/DROP permissions
- **Database exists**: Railway creates the database automatically
- **Check migration logs**: Look in Railway service logs for migration output
- **Manual migration**: You can SSH into the container and run migrations manually if needed

### Ghost Won't Start

- **Check logs**: Railway provides detailed logs in the dashboard
- **Port configuration**: Ghost runs on port 2368, Railway handles port mapping automatically
- **Environment variables**: Ensure all required variables are set
- **Content directory**: The entrypoint creates the content directory automatically

### App Not Accessible

- **Domain configuration**: Ensure the `url` environment variable matches your Railway domain
- **Public domain**: Railway provides a public domain, check the service settings
- **Custom domain**: If using a custom domain, configure it in Railway settings first

## Build Process

The production Dockerfile uses a multi-stage build:

1. **Dependencies stage**: Installs all dependencies
2. **Builder stage**: Builds all packages using Nx (`yarn build`)
3. **Production stage**: Creates minimal runtime image with only production dependencies

Build stages include:
- Building React apps (admin-x-settings, posts, stats, activitypub)
- Building Ember admin
- Building Ghost core assets
- Building public apps (portal, comments-ui, etc.)

## Performance Tips

1. **Use Railway's variable references**: This ensures database credentials stay in sync
2. **Enable caching**: Railway caches Docker layers automatically
3. **Monitor resource usage**: Check Railway metrics for CPU/memory usage
4. **Database optimization**: Railway MySQL is optimized, but monitor query performance

## Security Notes

1. **Environment variables**: Never commit secrets to the repository
2. **Database access**: Use Railway's internal networking when possible
3. **URL configuration**: Always use HTTPS URLs in production
4. **Updates**: Keep Ghost updated for security patches

## Support

- **Railway Docs**: [docs.railway.app](https://docs.railway.app)
- **Ghost Docs**: [ghost.org/docs](https://ghost.org/docs)
- **Ghost Forum**: [forum.ghost.org](https://forum.ghost.org)

## Notes

- First build will take longer (10-15 minutes) due to building all packages
- Subsequent builds use Docker layer caching for faster builds
- Ghost runs on port 2368 (Railway handles port mapping automatically)
- The entrypoint script waits up to 60 seconds for database connection
- Migrations run automatically on every deploy

