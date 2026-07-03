# Deployment Guide

## Railway Setup

### Prerequisites
- GitHub repository connected to Railway
- Railway account: https://railway.app

### Initial Setup

**Railway project created:** https://railway.com/project/008623f9-fab9-4dbe-befe-6ba07599e752

1. **Add Backend Service via GitHub** (Recommended)
   - Go to Railway dashboard: https://railway.app/project/008623f9-fab9-4dbe-befe-6ba07599e752
   - Click "+ New" → "GitHub Repo"
   - Select your repository
   - Set **Root Directory**: `backend`
   - Railway auto-detects Dockerfile
   - Click "Deploy"

2. **PostgreSQL Database** (Already added ✓)
   - Database is running
   - `DATABASE_URL` variable auto-created

3. **Configure Environment Variables**
   
   In Railway dashboard, add these variables:
   ```
   PORT=8080
   JWT_SECRET=<generate-secure-random-string>
   DATABASE_URL=<auto-populated-by-railway>
   ```
   
   Generate JWT secret:
   ```bash
   openssl rand -base64 32
   ```

4. **Add GitHub Actions Secret**
   
   Get Railway token:
   ```bash
   railway tokens
   ```
   
   Add to GitHub repo:
   - Settings → Secrets → Actions
   - New secret: `RAILWAY_TOKEN` = <your-token>

### Database Migrations

Railway doesn't auto-run migrations. Options:

**Option 1: Manual via Railway CLI**
```bash
railway run psql $DATABASE_URL -f migrations/000001_auth_schema.up.sql
```

**Option 2: Add migration step to Dockerfile**
```dockerfile
# Add before CMD in Dockerfile
RUN apk add --no-cache postgresql-client
COPY migrations/ ./migrations/
CMD ["sh", "-c", "psql $DATABASE_URL -f migrations/000001_auth_schema.up.sql && ./dates-api"]
```

**Option 3: Use migration tool**
```bash
# Install golang-migrate
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Run in Railway
railway run migrate -path ./migrations -database $DATABASE_URL up
```

### Deployment

**Auto-deploy on push to main:**
- Pushes to `main` branch trigger GitHub Actions
- Tests run → Docker builds → Deploys to Railway

**Manual deploy:**
```bash
cd backend
railway up
```

**View logs:**
```bash
railway logs
```

### Health Check

After deployment, test:
```bash
# Get Railway URL from dashboard
curl https://your-app.railway.app/api/health

# Test auth
curl -X POST https://your-app.railway.app/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass123"}'
```

### Rollback

```bash
# List deployments
railway status

# Rollback via dashboard
# Or redeploy previous commit
git revert HEAD
git push origin main
```

### Monitoring

Railway dashboard shows:
- CPU/Memory usage
- Request metrics
- Deployment history
- Real-time logs

### Cost Estimate

Railway pricing (2026):
- Hobby: $5/month (500 hours, 512MB RAM)
- Pro: $20/month (unlimited hours, scalable)
- PostgreSQL: Included in plan

## Local Development

```bash
# Run locally
cd backend
go run ./cmd/dates-api

# Build Docker image
docker build -t dates-api .
docker run -p 8080:8080 --env-file .env dates-api

# Test
make test
```

## CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/deploy.yml`):

1. **Test** - Runs on all PRs and pushes
   - `go test ./...`
   - `go vet ./...`
   - Format check

2. **Build** - Only on main branch
   - Docker build with cache
   - Validates Dockerfile

3. **Deploy** - Only on main branch
   - Deploys to Railway
   - Zero-downtime rolling update

## Troubleshooting

**Deployment fails:**
```bash
railway logs --tail 100
```

**Database connection issues:**
- Check `DATABASE_URL` in Railway dashboard
- Verify PostgreSQL service is running
- Check network policies

**Port conflicts:**
- Railway auto-assigns port via `PORT` env var
- Ensure app reads `PORT` from environment

**Build failures:**
- Check Dockerfile syntax
- Verify all dependencies in go.mod
- Check build logs in GitHub Actions
