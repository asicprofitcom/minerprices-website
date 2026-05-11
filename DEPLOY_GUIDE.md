# MinerPrices Deployment Guide

## Architecture

- **Frontend:** Static HTML + JavaScript
- **Backend:** Node.js/Express server (`server.js`)
- **Database:** Supabase (PostgreSQL)
- **Hosting:** Render.com (auto-deploys from GitHub)

---

## Local Development

```bash
# Install dependencies
npm install

# Run locally
npm run dev
# or
node server.js

# Visit: http://localhost:3000
```

---

## Environment Variables

Create a `.env` file in the root (not tracked by git):

```env
SUPABASE_URL=https://huzfnrgfcxlwvmrkoyge.supabase.co
SUPABASE_KEY=sb_publishable_s5ocl3sDwpefFYuw3V-JEQ_FQzXGTHZ
PORT=3000
NODE_ENV=production
```

**Or set in Render dashboard** (preferred for production).

---

## Deployment

### Automatic (Recommended)

1. Push to GitHub `main` branch:
   ```bash
   git add .
   git commit -m "Fix: description"
   git push origin main
   ```

2. Render automatically deploys via webhook
3. Monitor at: https://dashboard.render.com

### Manual (if needed)

```bash
# On your machine with Render CLI
render deploy
```

---

## File Structure

```
minerprices-website/
├── server.js              # Main Express server
├── package.json           # Dependencies
├── public/                # Static files served by Express
│   ├── images.html       # Image gallery page
│   ├── index.html        # Home page
│   ├── miner.html        # Miner details
│   ├── admin.html        # Admin panel
│   └── _routes.json      # (Cloudflare Pages config - ignore for Render)
├── functions/            # API functions (if using Cloudflare)
│   └── api.js
└── render.yaml           # Render deployment config
```

---

## API Routes

All routes are handled by `server.js`:

### Public Routes (Static Pages)
- `GET /` → `index.html`
- `GET /images` → `images.html`
- `GET /miner` → `miner.html`
- `GET /admin` → `admin.html`
- `GET /seller-dashboard` → `seller-dashboard.html`

### API Routes
- `GET /api/health` → Health check
- `GET /api/config` → Supabase config for frontend
- `GET /api/miner-images/:minerId` → Fetch images
- `POST /api/miner-images` → Upload image
- `DELETE /api/miner-images/:imageId` → Delete image

---

## Troubleshooting

### Port already in use
```bash
lsof -i :3000  # Find process
kill -9 <PID>  # Kill it
```

### Images not showing
1. Check Supabase is running
2. Verify `SUPABASE_URL` and `SUPABASE_KEY` in `.env`
3. Check database has `miners` and `miner_images` tables

### Render deploy fails
1. Check logs at https://dashboard.render.com
2. Verify environment variables are set
3. Ensure `npm install` completes without errors
4. Check `server.js` for syntax errors

---

## Key Files to Remember

- **Local credentials:** See `../CREDENTIALS.md` (workspace root, not in repo)
- **Git remote:** `git remote -v`
- **Last deploy:** `git log --oneline | head`

---

## Notes

- Secrets are NOT stored in this repo (`.gitignore`)
- Images are stored in Supabase, not local filesystem
- Server runs with `node server.js` in production
- Express serves both static files and API routes
