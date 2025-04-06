# MacMonitor Website

This directory contains the source code for the MacMonitor marketing website. It's a static website built with HTML, CSS (using Tailwind CSS), and JavaScript.

## Directory Structure

```
website/
├── README.md           # This file
├── index.html          # Homepage
├── guide.html          # User guide page
├── download.html       # Download page
├── css/                # CSS files
│   └── custom.css      # Custom styles
├── js/                 # JavaScript files
│   └── main.js         # Main JavaScript functionality
├── img/                # Images and assets
│   ├── logo.svg        # Main logo
│   ├── logo-white.svg  # Logo for dark backgrounds
│   └── ...
└── s3/                 # AWS deployment scripts
    └── deploy.sh       # S3 deployment script
```

## Technology Stack

- **HTML5**: Semantic markup for content structure
- **CSS**: Custom styles with Tailwind CSS framework
- **JavaScript**: Enhanced interactivity and user experience
- **Tailwind CSS**: Via CDN for utility-first styling
- **AWS S3**: Hosting platform

## Local Development

To work on this website locally, simply open the HTML files in your browser. Since this is a static website, no build process or server is required for basic development.

For a more complete development experience with live reload:

1. Install a simple HTTP server like [live-server](https://www.npmjs.com/package/live-server)
   ```bash
   npm install -g live-server
   ```

2. Run the server from the website directory
   ```bash
   cd /path/to/MacMonitor/website
   live-server
   ```

3. The website will open in your default browser and automatically reload when you make changes

## Deployment

### AWS S3 Deployment

The website is designed to be deployed to Amazon S3 as a static website. A deployment script is provided in the `s3` directory.

1. Make sure you have AWS CLI installed and configured with the appropriate credentials
   ```bash
   # Check if AWS CLI is installed
   aws --version
   
   # Configure AWS credentials if needed
   aws configure
   ```

2. Run the deployment script
   ```bash
   # Make the script executable if it's not already
   chmod +x s3/deploy.sh
   
   # Run the script
   ./s3/deploy.sh
   ```

3. The script will automatically:
   - Create the S3 bucket if it doesn't exist
   - Configure the bucket for static website hosting
   - Upload all website files with appropriate metadata
   - Set proper content types and cache headers

### Custom Domain Setup

To use a custom domain with your S3 website:

1. Register a domain if you don't already have one
2. Create a CNAME record pointing to your S3 website endpoint
3. For better performance, consider setting up AWS CloudFront

## SEO Optimization

This website includes several SEO optimizations:

- Semantic HTML structure
- Meta descriptions and keywords
- Open Graph and Twitter Card meta tags for social sharing
- Responsive design for all devices
- Proper heading hierarchy
- Image alt text
- Sitemap.xml (to be created when deployed)

## Making Changes

When making changes to the website:

1. Ensure all pages maintain consistent navigation and footer
2. Update the meta tags if content changes significantly
3. Test responsive behavior on multiple device sizes
4. Optimize any new images before adding them

## License

This website is part of the MacMonitor project and is released under the same [MIT License](../LICENSE).
