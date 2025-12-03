# 🐛 Troubleshooting Guide

## Common Issues and Solutions

### 🚨 Backend Not Detected

#### Problem
```
❌ ERROR: No running backends detected on common ports
```

#### Solutions

**1. Check what's actually running**
```bash
# See all listening ports
netstat -tlnp | grep LISTEN

# Check specific port
netstat -tlnp | grep :8000
```

**2. Test your backend manually**
```bash
# Test with curl
curl http://localhost:8000
curl http://omar.localhost:8000
curl http://127.0.0.1:8000

# If these don't work, your backend isn't accessible
```

**3. Common backend startup commands**
```bash
# Django
python manage.py runserver 0.0.0.0:8000

# Flask
flask run --host=0.0.0.0 --port=8000

# Node.js/Express
npm start

# Spring Boot
mvn spring-boot:run
```

**4. Check firewall/binding**
```bash
# Make sure backend binds to all interfaces (0.0.0.0) not just 127.0.0.1
# Many development servers default to localhost-only
```

---

### 🌐 Tunnel Creation Fails

#### Problem
```
❌ ERROR: Tunnel failed to start within 20 seconds
```

#### Solutions

**1. Check Cloudflared installation**
```bash
# Verify binary exists and works
ls -la bin/cloudflared
./bin/cloudflared --version

# If missing or corrupted, delete and retry
rm -f bin/cloudflared
./tunnel.sh start
```

**2. Network connectivity test**
```bash
# Test internet connection
curl -I https://api.cloudflare.com

# Test Cloudflare tunnel service
curl -I https://trycloudflare.com
```

**3. Check logs for details**
```bash
./tunnel.sh logs

# Look for specific errors like:
# - "connection refused"
# - "network unreachable"  
# - "permission denied"
```

**4. Firewall/Proxy issues**
```bash
# Corporate networks may block tunnel protocols
# Try different network or ask IT about proxy settings

# Check if running behind corporate proxy
echo $http_proxy $https_proxy
```

---

### 🔗 Public URL Not Accessible

#### Problem
```
❌ Status: Not accessible
```

#### Solutions

**1. Wait a bit longer**
```bash
# Cloudflare edge propagation can take 1-2 minutes
# Try again after waiting
sleep 60 && curl https://your-url.trycloudflare.com
```

**2. Check URL format**
```bash
# Make sure you're using the exact URL from the script
./tunnel.sh url

# Common mistake: adding extra paths
# ✅ Correct: https://abc.trycloudflare.com
# ❌ Wrong: https://abc.trycloudflare.com/api
```

**3. Test from different network**
```bash
# Try from mobile data or different WiFi
# Some networks may have restrictions
```

**4. Check backend health**
```bash
# Make sure local backend is still responsive
curl http://localhost:8000

# If local backend is down, public URL won't work
```

---

### 💀 Tunnel Process Dies

#### Problem
```
❌ Tunnel Process: Not running
```

#### Solutions

**1. Check what killed it**
```bash
# Look at the end of logs
./tunnel.sh logs

# Common causes:
# - Backend stopped responding
# - System went to sleep
# - Network connection lost
# - Out of memory
```

**2. Check system resources**
```bash
# Memory usage
free -h

# Disk space
df -h

# System logs for OOM killer
dmesg | grep -i "killed process"
```

**3. Restart tunnel**
```bash
./tunnel.sh restart
```

**4. Keep tunnel alive (advanced)**
```bash
# Create a watchdog script
while true; do
    if ! ./tunnel.sh status | grep -q "Running"; then
        echo "Restarting dead tunnel..."
        ./tunnel.sh restart
    fi
    sleep 60
done
```

---

### 🔒 Permission Errors

#### Problem
```
❌ ERROR: Permission denied
```

#### Solutions

**1. Make script executable**
```bash
chmod +x tunnel.sh
```

**2. Check file permissions**
```bash
# Script should be executable
ls -la tunnel.sh

# Directory should be writable
ls -lad tunnel-solutions/
```

**3. Don't run as root**
```bash
# Run as regular user, not sudo
# Cloudflared doesn't need root privileges
```

---

### 📱 CORS/Backend Issues

#### Problem
```
Browser console: "CORS policy" or "Mixed content"
```

#### Solutions

**1. CORS Headers (Backend fix)**
```python
# Django - add to settings.py
CORS_ALLOW_ALL_ORIGINS = True  # For development only!
CORS_ALLOWED_ORIGINS = [
    "https://your-tunnel-url.trycloudflare.com",
]

# Flask
from flask_cors import CORS
CORS(app, origins=["https://your-tunnel-url.trycloudflare.com"])
```

**2. Mixed Content (HTTPS/HTTP)**
```bash
# Problem: Your backend serves HTTP, tunnel provides HTTPS
# Solution: Update your frontend to use relative URLs
# ✅ Good: "/api/data" 
# ❌ Bad: "http://localhost:8000/api/data"
```

**3. Django ALLOWED_HOSTS**
```python
# Add to Django settings.py
ALLOWED_HOSTS = [
    'localhost',
    '127.0.0.1', 
    'your-tunnel-url.trycloudflare.com',
    # Or for development:
    '*'
]
```

---

### 🎯 Specific Backend Issues

#### Django "No tenant for hostname"
```
This is NORMAL for multi-tenant Django apps
Your API endpoints will work fine:
✅ https://tunnel-url.trycloudflare.com/api/
❌ https://tunnel-url.trycloudflare.com/ (root path)
```

#### Node.js/Express ECONNREFUSED
```bash
# Make sure Express binds to all interfaces
app.listen(8000, '0.0.0.0', () => {
    console.log('Server running on 0.0.0.0:8000');
});

# Not just:
app.listen(8000); // This might only bind to 127.0.0.1
```

#### React Development Server
```bash
# React dev server needs HOST=0.0.0.0
HOST=0.0.0.0 npm start

# Or in .env file:
echo "HOST=0.0.0.0" > .env
```

---

### 🌍 Network-Specific Issues

#### Corporate Networks/VPNs
```bash
# Some corporate networks block tunnel protocols
# Try these steps:

1. Disconnect from VPN temporarily
2. Try mobile hotspot
3. Ask IT about firewall rules for:
   - Outbound HTTPS (443)
   - Cloudflare IP ranges
   - WebSocket connections
```

#### Slow Connection
```bash
# Tunnel adds latency - test baseline:
ping 8.8.8.8
curl -w "%{time_total}" -s https://google.com > /dev/null

# If baseline is slow (>500ms), tunnel will be slower
```

---

### 📊 Monitoring and Debugging

#### Real-time Monitoring
```bash
# Watch tunnel status
watch -n 5 './tunnel.sh status'

# Monitor logs live
tail -f logs/tunnel.log

# Monitor backend health
watch -n 10 'curl -s http://localhost:8000 && echo "OK" || echo "FAIL"'
```

#### Debugging Commands
```bash
# Full system check
echo "=== System Info ==="
uname -a
free -h
df -h /

echo "=== Network ==="
curl -I https://api.cloudflare.com
netstat -tlnp | grep :8000

echo "=== Tunnel Status ==="  
./tunnel.sh status
./tunnel.sh logs | tail -10
```

#### Performance Testing
```bash
# Test tunnel performance
time curl -s https://your-tunnel-url.trycloudflare.com

# Compare with direct access
time curl -s http://localhost:8000

# Load testing (careful!)
for i in {1..10}; do
    curl -s https://your-tunnel-url.trycloudflare.com &
done
wait
```

---

### 🔧 Advanced Troubleshooting

#### Binary Issues
```bash
# Re-download cloudflared
rm -f bin/cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o bin/cloudflared
chmod +x bin/cloudflared
./bin/cloudflared --version
```

#### Clean Restart
```bash
# Nuclear option - clean everything
./tunnel.sh stop
rm -rf bin/ logs/
./tunnel.sh start
```

#### Multiple Backends
```bash
# If you have multiple services, tunnel them separately
./tunnel.sh start localhost:8000  # Backend API
# In another terminal:
./tunnel.sh start localhost:3000  # Frontend dev server
```

---

### ❓ When to Seek Help

**Check these first:**
1. ✅ Backend accessible locally (`curl http://localhost:8000`)
2. ✅ Internet connection working (`curl https://google.com`)
3. ✅ Script has execute permissions (`ls -la tunnel.sh`)
4. ✅ No corporate firewall blocking
5. ✅ Cloudflared binary working (`./bin/cloudflared --version`)

**Still not working?**
1. 📄 Check `./tunnel.sh logs` for specific error messages
2. 🧪 Try different backend URL format
3. 🌐 Test from different network
4. 💻 Try on different machine
5. 📋 Use `./tunnel.sh status` for full diagnostic

**Last resort:**
```bash
# Manual tunnel creation (bypass our script)
./bin/cloudflared tunnel --url http://localhost:8000

# If this works, the issue is in our script
# If this fails, it's a network/system issue
```

---

## 📞 Quick Diagnostic Script

Save this as `diagnose.sh` for quick troubleshooting:

```bash
#!/bin/bash
echo "🔍 Quick Diagnostic"
echo "==================="

echo "1. Script permissions:"
ls -la tunnel.sh

echo "2. Backend test:"
curl -s --connect-timeout 3 http://localhost:8000 && echo "✅ OK" || echo "❌ FAIL"

echo "3. Internet test:"
curl -s --connect-timeout 3 https://api.cloudflare.com && echo "✅ OK" || echo "❌ FAIL"

echo "4. Binary test:"
./bin/cloudflared --version 2>/dev/null && echo "✅ OK" || echo "❌ FAIL"

echo "5. Tunnel status:"
./tunnel.sh status

echo "6. Recent logs:"
tail -5 logs/tunnel.log 2>/dev/null || echo "No logs found"
```

Run with: `chmod +x diagnose.sh && ./diagnose.sh`