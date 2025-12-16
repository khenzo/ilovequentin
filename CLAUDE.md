# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Hugo static site blog called "I Love Quentin" (ilovequentin.it), a personal blog by Vincenzo Prencipe featuring literary posts, poetry, and personal essays. The site uses Hugo v0.152.2 Extended and is integrated with Forestry CMS for content management.

## Build and Development Commands

### Local Development
```bash
# Start Hugo development server
hugo server -D -E -F --port 8080 --bind 0.0.0.0 --renderToDisk -d public

# Build for production
hugo

# Build with drafts included
hugo -D
```

### Hugo Version Requirements
- Minimum version: 0.38
- Currently installed: v0.152.2 Extended
- Target version (per Forestry config): 0.47.1

## Content Structure

### Content Organization
The blog posts are organized in three main categories under `content/posts/`:

1. **Dalle verdi colline di Hollywood** - Literary pieces inspired by Bukowski and Beat Generation
2. **Mi piacciono di più** - Personal preferences and reflections
3. **Planet Terron** - Social commentary and storytelling

### Content Types
- **Posts**: Blog entries with front matter including `title`, `author`, `type`, `date`, `url`, `featured_image`, `categories`, and `tags`
- **Pages**: Static pages like "Me" section
- **Blog listing**: Aggregated view at `/blog`

### Front Matter Format
Posts use YAML front matter with these key fields:
```yaml
---
title: Post Title
author: khenzo
type: post
date: 2008-06-26T08:09:25+00:00
url: /2008/06/26/slug
featured_image:
  - /wp-content/uploads/path/to/image.jpg
categories:
  - Category Name
tags:
  - tag1
  - tag2
---
```

## Architecture

### Theme System
- Single custom theme located in `themes/default/`
- Theme configuration: `themes/default/theme.toml`
- Theme uses Bootstrap, Font Awesome, Fancybox, and Open Sans font

### Layout Hierarchy
The homepage (`themes/default/layouts/index.html`) is composed of partials in this order:
1. `head.html` - Meta tags, CSS, OpenGraph/Twitter Card metadata
2. `header.html` - Site navigation
3. `hero.html` - Hero section with background image from `data/hero.toml`
4. `description.html` - Site description
5. `featured.html` - Featured posts
6. `divider.html` - Visual separator from `data/divider.toml`
7. `mybest.html` - Latest/best posts
8. `footer.html` - Site footer

### Data Files
Configuration data is stored in `data/` directory:
- `hero.toml` - Hero section background image
- `gallery.toml` - Gallery links and images (e.g., Schegge di Liberazione)
- `divider.toml` - Divider section configuration

### Post Templates
- Single post: `themes/default/layouts/post/single.html` - Full post view with featured image, metadata, author avatar
- Post list: `themes/default/layouts/post/list.html` - Category-grouped post listings
- Blog listing: `themes/default/layouts/blog/list.html` - Shows 2 most recent posts per category

### Head Partial Structure
`themes/default/layouts/partials/head.html` contains duplicate `<head>` sections (historical artifact). It includes:
- Meta tags for SEO and responsive design
- Google site verification
- Bootstrap, Font Awesome, custom CSS
- OpenGraph tags for social sharing
- Twitter Card metadata
- Dynamic meta generation based on post parameters

## Site Configuration

Key settings in `config.toml`:
- Theme: "default"
- Title: "I Love Quentin"
- Hugo min version: 0.38
- Summary length: 30 words
- Date format: "6 January 2006"
- Author avatar URL (Google Drive hosted)
- Menu structure with Home and Blog links
- Front matter date handling prioritizes git lastmod

## Forestry CMS Integration

The site uses Forestry.io for content management:
- Admin path configured in `.forestry/settings.yml`
- Content sections: Me, Pages, Posts, Blog
- Upload directory: `static/uploads/wp-content/uploads`
- Instant preview uses Hugo server on port 8080
- Files created with `.html` extension by default

### Front Matter Templates
- `.forestry/front_matter/templates/page.yml` - Page template
- `.forestry/front_matter/templates/post.yml` - Post template

## Static Assets

- Static files: `static/` directory
- Uploads: `static/uploads/wp-content/uploads/`
- Theme assets: `themes/default/static/`
- Vendor libraries: jQuery Cookie, Bootstrap, Font Awesome, Fancybox

## Git Workflow

The repository uses `master` as the main branch. Recent activity shows content cleanup (removal of old HTML files) and Forestry CMS updates to posts.

## Important Notes

- The site was migrated from WordPress (evident from `/wp-content/` paths in image URLs)
- Featured images often reference old WordPress upload paths
- Posts may contain inline HTML and WordPress-specific shortcodes
- The head.html partial has duplicate `<head>` tags that should be consolidated
- Some posts use both `.md` and `.html` extensions
- Categories are used for taxonomy-based post grouping on the blog listing page
