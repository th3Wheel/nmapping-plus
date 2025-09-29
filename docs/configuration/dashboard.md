# Dashboard Configuration

This document describes how to configure the nMapping+ dashboard container for secure, reliable, and customizable web access.

## Configuration File Location

- `/dashboard/config/dashboard.conf` — Main dashboard settings
- `/dashboard/config/notifications.conf` — Email, webhook, and alert settings

## Key Settings

- **Web Port**: Default is 80 (HTTP) and/or 443 (HTTPS)
- **SSL/TLS**: Enable HTTPS with Let's Encrypt or custom certificates
- **Authentication**: (Optional) Enable login for dashboard access
- **API Keys**: (Optional) Restrict API access with tokens
- **Notification Channels**: Configure email, webhook, or SIEM alerts

## Example: dashboard.conf

```
PORT=443
SSL_ENABLED=true
CERT_PATH=/etc/letsencrypt/live/your-domain/fullchain.pem
KEY_PATH=/etc/letsencrypt/live/your-domain/privkey.pem
AUTH_REQUIRED=true
```

## Example: notifications.conf

```
EMAIL_ENABLED=true
EMAIL_FROM=alerts@yourdomain.com
EMAIL_TO=admin@yourdomain.com
WEBHOOK_URL=https://hooks.example.com/notify
```

## Best Practices

- Always enable HTTPS in production
- Use strong passwords and/or API keys
- Limit dashboard access to trusted networks
- Regularly test notification channels

## References

- [Flask Configuration Patterns](https://flask.palletsprojects.com/en/latest/config/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Web Application Security](https://owasp.org/www-project-top-ten/)
