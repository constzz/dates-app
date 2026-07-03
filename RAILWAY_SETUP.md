# Railway Setup - Quick Start

**GitHub Repository**: https://github.com/constzz/dates-app
**Railway Project**: https://railway.com/project/008623f9-fab9-4dbe-befe-6ba07599e752

## Current Status
✓ Project created: `dates-app`
✓ PostgreSQL database added
✓ Code pushed to GitHub
✗ Backend service (needs GitHub integration)

## Next Steps

### 1. Add Backend Service via GitHub Integration

1. Open Railway: https://railway.com/project/008623f9-fab9-4dbe-befe-6ba07599e752

2. Click **"+ New"** → **"GitHub Repo"**

3. Select **constzz/dates-app**

4. **Important**: Set **Root Directory** to `backend`

5. Railway will automatically:
   - Detect Dockerfile
   - Build the image
   - Deploy

### 2. Configure Environment Variables

In the backend service settings:

```
PORT=8080
JWT_SECRET=8y+lfqS+puAxrNaQBUopixfpPj1PNmWRdTXlIaiyVbA=
DATABASE_URL=${{Postgres.DATABASE_URL}}
APP_ENV=production
```

**Note**: `DATABASE_URL` reference connects to Postgres automatically.

### 3. Run Database Migrations

After first deployment:

```bash
~/.npm-global/bin/railway link -p dates-app
~/.npm-global/bin/railway run psql $DATABASE_URL -f backend/migrations/000001_auth_schema.up.sql
```

### 4. Generate Railway Token for GitHub Actions

```bash
~/.npm-global/bin/railway tokens
```

Add to GitHub repo secrets:
- Go to: https://github.com/constzz/dates-app/settings/secrets/actions
- New secret: `RAILWAY_TOKEN` = <your-token>

### 5. Auto-Deploy is Ready! ✓

Pushes to `main` branch will automatically:
- Run tests via GitHub Actions
- Build Docker image
- Deploy to Railway

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
