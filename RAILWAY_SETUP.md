# Railway Setup - Quick Start

Project created: https://railway.com/project/008623f9-fab9-4dbe-befe-6ba07599e752

## Current Status
✓ Project created: `dates-app`
✓ PostgreSQL database added
✗ Backend service (needs GitHub integration)

## Next Steps

### 1. Push Code to GitHub
```bash
cd /Users/kostia/my_project
git add .
git commit -m "Add Railway deployment config"
git push origin main
```

### 2. Add Backend Service via Dashboard

1. Open: https://railway.com/project/008623f9-fab9-4dbe-befe-6ba07599e752

2. Click **"+ New"** → **"GitHub Repo"**

3. Connect your GitHub account if needed

4. Select your repository

5. **Important**: Set **Root Directory** to `backend`

6. Railway will:
   - Detect `Dockerfile`
   - Build the image
   - Deploy automatically

7. Click **"Deploy"**

### 3. Configure Environment Variables

In the backend service settings:

```
PORT=8080
JWT_SECRET=<run: openssl rand -base64 32>
DATABASE_URL=${{Postgres.DATABASE_URL}}
APP_ENV=production
```

**Note**: `DATABASE_URL` reference connects to Postgres automatically.

### 4. Run Database Migrations

After first deployment:

```bash
~/.npm-global/bin/railway link -p dates-app
~/.npm-global/bin/railway run psql $DATABASE_URL -f backend/migrations/000001_auth_schema.up.sql
```

### 5. Generate Railway Token for GitHub Actions

```bash
~/.npm-global/bin/railway tokens
```

Add to GitHub repo secrets:
- Settings → Secrets → Actions
- New secret: `RAILWAY_TOKEN` = <your-token>

### 6. Enable Auto-Deploy

Push to `main` branch → GitHub Actions → Tests → Build → Deploy to Railway

## Test Deployment

```bash
# Get service URL from Railway dashboard
curl https://your-app.railway.app/api/health

# Test auth
curl -X POST https://your-app.railway.app/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass123"}'
```

## Troubleshooting

**Backend not deploying?**
- Check Root Directory is set to `backend`
- Verify Dockerfile exists in backend/
- Check build logs in Railway dashboard

**Database connection failed?**
- Verify `DATABASE_URL` variable references: `${{Postgres.DATABASE_URL}}`
- Check Postgres service is running
- Run migrations

**PORT issues?**
- Railway sets `PORT` env var automatically
- Config reads `PORT` first, falls back to `HTTP_ADDR`

## Manual Deploy (Alternative)

If GitHub integration not available:

```bash
cd backend
~/.npm-global/bin/railway link -p dates-app
~/.npm-global/bin/railway up --detach
```
