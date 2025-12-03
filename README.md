# 🌍 Universal Tunnel Solutions

**Instantly expose any local backend to the internet** - Works with `localhost:8000`, `omar.localhost:3000`, or any local URL.

## 🚀 Quick Start (30 seconds)

```bash
# Clone or download this folder
cd tunnel-solutions

# Make the script executable  
chmod +x tunnel.sh

# Start tunnel (auto-detects your backend)
./tunnel.sh start

# Or specify your exact URL
./tunnel.sh start omar.localhost:8000
```

**Output:**
```
🎉 SUCCESS: Tunnel created successfully!

═══════════════════════════════════════════════════════════════
🌐 LOCAL URL:  http://omar.localhost:8000
🚀 PUBLIC URL: https://your-unique-name.trycloudflare.com
═══════════════════════════════════════════════════════════════
```

## 📋 Commands

| Command | Description | Example |
|---------|-------------|---------|
| `./tunnel.sh start` | Auto-detect and tunnel | `./tunnel.sh start` |
| `./tunnel.sh start URL` | Tunnel specific URL | `./tunnel.sh start localhost:3000` |
| `./tunnel.sh status` | Show tunnel status | `./tunnel.sh status` |
| `./tunnel.sh stop` | Stop tunnel | `./tunnel.sh stop` |
| `./tunnel.sh url` | Get public URL | `./tunnel.sh url` |
| `./tunnel.sh logs` | View tunnel logs | `./tunnel.sh logs` |

## ✅ Supported URLs

The script automatically handles:

- `localhost:8000` → `http://localhost:8000`
- `omar.localhost:3000` → `http://omar.localhost:3000`  
- `127.0.0.1:5000` → `http://127.0.0.1:5000`
- `http://localhost:8080` → `http://localhost:8080`
- `https://myapp.local:443` → `https://myapp.local:443`

## 🔧 Auto-Detection

If you don't specify a URL, the script automatically checks these common backends:

- `http://localhost:8000` (Django default)
- `http://localhost:3000` (React/Node default)  
- `http://localhost:5000` (Flask default)
- `http://localhost:8080` (Java/Spring default)
- `http://omar.localhost:8000` (Your custom domain)
- And more...

## 🏗️ What Gets Installed

The script automatically downloads required tools if not present:

- **Cloudflared binary** (~40MB) - Downloads once, works offline after
- **Creates folders**:
  - `bin/` - Binary files
  - `logs/` - Tunnel logs and status files

## 🎯 Use Cases

### For Retool Integration
```bash
./tunnel.sh start omar.localhost:8000
# Use the public URL in Retool as your API base
```

### For Team Sharing  
```bash
./tunnel.sh start localhost:3000
# Share the public URL with teammates
```

### For Webhook Testing
```bash
./tunnel.sh start localhost:8000
# Use public URL as webhook endpoint
```

## 📊 Monitoring

```bash
# Check if everything is working
./tunnel.sh status

# View live logs  
./tunnel.sh logs

# Get just the public URL
./tunnel.sh url
```

## 🔄 Persistence

- **URLs change** on restart (free Cloudflare tunnels)
- **Process survives** until you stop it or reboot
- **Auto-recovery** - script handles disconnections
- **Background operation** - runs in background automatically

## 🆚 Alternative Solutions

| Solution | This Script | ngrok | LocalTunnel | 
|----------|-------------|-------|-------------|
| **Cost** | Free | $8+/month | Free |
| **Setup Time** | 30 seconds | 2 minutes | 1 minute |
| **Reliability** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Auto-detect** | ✅ | ❌ | ❌ |
| **Any URL** | ✅ | ❌ | ❌ |

## 📁 Project Structure

```
tunnel-solutions/
├── tunnel.sh              # Main script (run this)
├── README.md              # This file
├── docs/
│   ├── TECHNOLOGY.md      # Technical details
│   └── TROUBLESHOOTING.md # Common issues
├── bin/                   # Auto-created
│   └── cloudflared        # Auto-downloaded
└── logs/                  # Auto-created
    ├── tunnel.log         # Tunnel logs
    ├── tunnel.pid         # Process ID
    └── public_url.txt     # Current public URL
```

## 🔒 Security Notes

- ✅ **Perfect for development** and testing
- ✅ **Great for demos** and team collaboration  
- ⚠️ **Public URLs** are accessible by anyone who has the link
- ⚠️ **Free tunnels** have no uptime guarantee
- 🔐 **Add authentication** to your backend for sensitive data

## 🚨 If It Doesn't Work - What to Do

### 1. Quick Diagnostic Commands
```bash
# Check status anytime
./tunnel.sh status

# Get just the URL
./tunnel.sh url  

# Stop when done
./tunnel.sh stop

# Restart if needed
./tunnel.sh restart

# View logs for errors
./tunnel.sh logs
```

### 2. Common Issues & Solutions

#### 🔍 Backend Not Detected
```bash
# Check what's running on your system
netstat -tlnp | grep :8000

# Test your backend manually
curl http://localhost:8000
curl http://omar.localhost:8000

# If nothing responds, start your backend first:
python manage.py runserver 0.0.0.0:8000

# Then specify exact URL
./tunnel.sh start omar.localhost:8000
```

#### 🌐 Public URL Not Accessible
```bash
# Wait 1-2 minutes (Cloudflare propagation)
sleep 60 && ./tunnel.sh status

# If still not working, restart tunnel
./tunnel.sh restart

# Check logs for errors
./tunnel.sh logs
```

#### 🔧 Tunnel Won't Start
```bash
# Check internet connection
curl -I https://api.cloudflare.com

# Clean restart
./tunnel.sh stop
rm -rf bin/ logs/
./tunnel.sh start

# Check system requirements (see TECHNOLOGY.md)
```

### 3. What We Did to Make This Work
- ✅ **Auto-detection**: Script finds your backend automatically
- ✅ **Smart URL handling**: Works with any format (localhost, custom domains)
- ✅ **Process management**: Handles start/stop/restart cleanly
- ✅ **Health monitoring**: Checks both local and public URLs
- ✅ **Error recovery**: Auto-downloads tools, handles network issues
- ✅ **Comprehensive logging**: Full visibility into what's happening

### 4. Emergency Troubleshooting
```bash
# Nuclear option - clean everything and start over
./tunnel.sh stop
rm -rf bin/ logs/
./tunnel.sh start your-backend-url

# Manual tunnel (bypass our script entirely)  
./bin/cloudflared tunnel --url http://localhost:8000

# If manual works but script doesn't, check script permissions
chmod +x tunnel.sh
```

### 5. Need Permanent URL?
- Use the VPS solution in `docs/VPS_SETUP.md`
- Or upgrade to Cloudflare Teams for named tunnels

## 🏃‍♂️ Quick Examples

```bash
# Django development server
python manage.py runserver 0.0.0.0:8000
./tunnel.sh start localhost:8000

# React development server  
npm start  # Usually runs on :3000
./tunnel.sh start localhost:3000

# Custom domain backend
./tunnel.sh start omar.localhost:8000

# Any backend with auto-detection
./tunnel.sh start
```

---

## 📞 Support

- 📖 **Full docs**: See `docs/` folder
- 🔧 **Tech details**: `docs/TECHNOLOGY.md`
- 🐛 **Issues**: `docs/TROUBLESHOOTING.md`
- 💡 **Questions**: Check the documentation first

**Ready to tunnel? Run `./tunnel.sh start` and you're live in 30 seconds! 🚀**