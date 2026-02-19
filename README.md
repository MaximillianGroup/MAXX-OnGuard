
<img width="1280" height="640" alt="sparxstar-maxx-onguard" src="https://github.com/user-attachments/assets/e75a1aeb-09b0-47c4-bfbe-ac138ad3b18b" />

# MaxX OnGauard&trade; WordPress Site Security

- Apache .htaccess + .conf files to secure your WordPress Site
- With 8G Bot Protection by Perishable Press
- *An .htaccess file that works!*

[![CI](https://github.com/MaximillianGroup/MAXX-OnGuard/actions/workflows/blank.yml/badge.svg)](https://github.com/MaximillianGroup/MAXX-OnGuard/actions/workflows/blank.yml)  [![CodeQL](https://github.com/MaximillianGroup/MAXX-OnGuard/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/MaximillianGroup/MAXX-OnGuard/actions/workflows/github-code-scanning/codeql)  [![Copilot code review](https://github.com/MaximillianGroup/MAXX-OnGuard/actions/workflows/copilot-pull-request-reviewer/copilot-pull-request-reviewer/badge.svg)](https://github.com/MaximillianGroup/MAXX-OnGuard/actions/workflows/copilot-pull-request-reviewer/copilot-pull-request-reviewer)

## Security Settings and Optimization Guide

This guide explains the combined use of `.htaccess` and `.conf` files to secure and optimize your WordPress website. It covers core security settings, performance optimization, bot protection, and integration with WordPress.

## Why Use Both .htaccess and .conf?

*This configuration provides a robust foundation for a secure and optimized WordPress site.* By using both files effectively, you create a comprehensive security and optimization strategy for your website. 

- **.htaccess:**  Provides a per-directory configuration for Apache, allowing fine-grained control over specific folders or files. It's ideal for implementing directory-specific security measures, rewrite rules, and custom configurations.
- **.conf:**  Provides a broader configuration for Apache, defining virtual hosts, server settings, and global configurations. It's essential for setting up SSL certificates, redirecting traffic, and managing server-wide security policies.

### It protects and improves performance with:

- **Core Security Settings:** Disables server signature, limits file upload size, protects against DOS attacks, and more.
- **Security Headers Enforce Best Practice:** Enforces Content Security Policy, CORS, and other security headers to protect against common web vulnerabilities.
- **Performance Optimization:** Enables GZIP compression, sets custom MIME types, and optimizes caching.
- **8G Firewall Bot Protections:** Implements a robust firewall to block suspicious requests and user agents.
- **WordPress Integration:** Includes specific rules for WordPress installations, including directory browsing protection.
- **Custom Error Handling:** Redirects invalid requests to a custom error page.

## Installation Instructions

1. **Create a new file named `.htaccess` in your website's root directory.**
2. **Copy and paste the entire code from this file into the new `.htaccess` file.**
3. **Save the file.**

## Recommendations and Adjustments

This `.htaccess` file is a comprehensive starting point for securing and optimizing your website. You may need to adjust certain sections based on your specific needs and preferences.

**Core Security Settings:**

- **`LimitRequestBody`:**  Adjust the file upload size (in bytes) to suit your specific needs.
- **`AddHandler`:**  Modify this directive to allow or disallow script execution for other file types.
- **`RewriteBase`:** Adjust this directive if your website is not located at the root directory.

**Security Headers:**

- **`Content-Security-Policy`:**  Carefully configure this directive to allow only the resources that your website needs.
- **`Access-Control-Allow-Origin`:**  Adjust the value to define allowed origins for your API or web applications.
- **`Strict-Transport-Security`:** Consider the value of `max-age` to balance security and browser caching.

**8G Firewall:**

- **`RewriteCond`:**  Customize the firewall rules to block specific user agents, remote hosts, or referrers that might be posing a security risk.

**WordPress Integration:**

- **`RewriteRule`:**  Adjust the rules to match the specific paths used in your WordPress installation.

**Custom Error Handling:**

- **`RewriteRule`:**  Modify the path to `error.html` to match the location of your custom error page.

**MIME Types and Charset Settings:**

- **`AddType`:**  Add or remove MIME types to match the file types used on your website.
- **`AddCharset`:** Adjust this directive to specify the desired character encoding for specific file types.

**Performance Optimization:**

- **`ExpiresByType`:**  Customize the cache expiration times to suit your specific needs.
- **`Header append Cache-Control`:**  Consider adding other cache control directives, such as `no-cache` or `must-revalidate`, to manage browser caching behavior.

## Overview of domain.conf File

This configuration file is designed to provide a secure and optimized Apache setup for a WordPress site.  It leverages SSL using Let's Encrypt certificates for secure HTTPS traffic and includes various security measures to protect the site from common vulnerabilities and attacks. 

## Modules and Listeners

This section loads essential Apache modules and configures the server to listen on both HTTP (port 80) and HTTPS (port 443).

```apache
# Load necessary modules
LoadModule ssl_module modules/mod_ssl.so
LoadModule headers_module modules/mod_headers.so
LoadModule rewrite_module modules/mod_rewrite.so

# Listen on HTTP and HTTPS ports
Listen 80
Listen 443
```

## HTTP to HTTPS Redirection
This section redirects all incoming HTTP traffic (port 80) to HTTPS, enforcing a secure connection for all users.

```apache
# HTTP VirtualHost to redirect all traffic to HTTPS
<VirtualHost *:80>
    ServerName sparxstar.com
    ServerAlias www.sparxstar.com

    # Redirect all HTTP requests to HTTPS
    RewriteEngine On
    RewriteRule ^/?(.*) https://%{SERVER_NAME}%{REQUEST_URI} [R=301,L]
</VirtualHost>
```
## HTTPS VirtualHost Configuration
This is the primary VirtualHost, handling all HTTPS traffic on port 443. It includes the main website settings, SSL certificates, and security configurations.

```apache
# HTTPS VirtualHost with SSL configuration
<VirtualHost *:443>
    ServerName sparxstar.com
    ServerAlias www.sparxstar.com

    # Document root for the site
    DocumentRoot /var/www/html

    # Enable SSL engine
    SSLEngine on
```
## SSL Certificates
This configuration uses Let's Encrypt certificates for secure HTTPS communication.

```apache
# SSL Certificates from Let's Encrypt
    SSLCertificateFile /etc/letsencrypt/live/sparxstar.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/sparxstar.com/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/sparxstar.com/chain.pem
```
## SSL Security
This section enforces strong encryption, preferred cipher order, and enables OCSP stapling for enhanced SSL security.

```apache
# Strong Ciphers and Enforcing Cipher Order
    SSLCipherSuite HIGH:!aNULL:!MD5
    SSLHonorCipherOrder on

    # Enable OCSP Stapling
    SSLUseStapling On
    SSLStaplingCache "shmcb:/var/log/apache2/ssl_stapling(32768)"
```
## WordPress Directory Permissions
This section defines the permissions for the WordPress directory (/var/www/html/wp-content) to enable .htaccess overrides and restrict access to certain files.

```apache
# Directory settings for WordPress root directory
    <Directory /var/www/html>
        # Allows .htaccess to handle Mod Rewrite and other rules
        AllowOverride All
        Require all granted
    </Directory>

    # Directory-level restrictions
    <Directory /var/www/html/wp-content>
        AllowOverride All
        Require all granted
    </Directory>
```
#3 Additional Security Settings
This section restricts script execution in the wp-content/uploads directory to prevent potential exploits.

```apache
# Restrict PHP, JS, and other script execution in uploads directory
    <Directory /var/www/html/wp-content/uploads>
        <FilesMatch "\.(php|js|cgi|as|pl|py|rb|sh)$">
           Require all denied
        </FilesMatch>
    </Directory>
```
## Optional Client Certificate Authentication
Client certificate authentication can be enabled to add an additional security layer, ensuring only clients with valid certificates can access the site.

```
# Optional: Client Certificate Authentication
    # Uncomment the lines below to require a client certificate
    # SSLVerifyClient require
    # SSLVerifyDepth 1
    # SSLCACertificateFile /path/to/ca.crt
```
##  Logging
This section configures Apache to log SSL-related events and access logs, which are crucial for debugging and security monitoring.

```apache
# Logging for SSL
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```
## Deployment Notes
After configuring the Apache server, restart Apache to apply the changes:

```apache
sudo systemctl restart apache2
```
## Recommendations
- **CORS:** In production, configure Header add Access-Control-Allow-Origin to specific origins instead of using *.
- **wp-admin Authentication:** Uncomment and configure the wp-admin directory block if you want to use Basic Authentication for the WordPress admin area.
- **Test Thoroughly:** After making changes, test your website thoroughly to ensure everything is working as expected and no mixed content issues have been introduced.

## **Important Notes:**

- **Use Code with Caution:** The provided `.htaccess` file includes powerful directives that can have a significant impact on your website's functionality. Carefully review the code and only make changes that you fully understand.
- **Test Thoroughly:**  Test your website after making any changes to `.htaccess` to ensure that everything is working correctly.
- **Backup Your Files:** Always create a backup of your website's files before making any changes to `.htaccess`.

*This configuration provides a robust foundation for a secure and optimized WordPress site. Remember to keep your SSL certificates up-to-date and monitor your Apache logs regularly for security incidents. Use Code with causion.*

This guide provides a starting point for securing and optimizing your website. Remember that security and performance are ongoing processes, so stay up-to-date with the latest best practices and recommendations.

**Disclaimer:** *This .htaccess and .conf configuration may not be suitable for your application, use with caution. While it incorporates best practices and security measures, it may not be suitable for all environments and may require adjustments based on your specific website and server setup. It is your responsibility to exercise due diligence and take appropriate precautions to secure your website. We make no warranties, express or implied, regarding the functionality, security, or suitability of this configuration for your specific needs. We are not responsible for any damages or losses, direct or indirect, arising from the use of this code.*


