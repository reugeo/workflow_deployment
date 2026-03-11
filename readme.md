# Telegram Google Calendar Automation (n8n)

An AI-powered automation workflow built in n8n that enables users to create, update, delete, and retrieve Google Calendar events directly from Telegram using natural language.

---

## 📌 Overview

This project connects Telegram, Gemini, and Google Calendar to build a conversational scheduling assistant.

Users can send messages like:

  - Schedule meeting at 9 am with Zahra on 8 December 2025  
  - Set a reminder tomorrow at 6pm to call mom  
  - Delete my meeting with Ravi next Monday  
  - What meetings do I have today?

The workflow processes the message, extracts structured event details using AI, performs the requested action in Google Calendar, and sends confirmation back via Telegram.

---

## 📁 Repository Structure

```
calendar_automation/
├── .github/
│   └── workflows/
│       └── deploy.yml           # GitHub Actions CI/CD pipeline
├── workflows/
│   └── Auto Calendar.json       # n8n workflow (loaded into container)
├── .dockerignore                # Files excluded from Docker image
├── .env.example                 # Template for environment variables
├── .gitignore                   # Files excluded from Git
├── Auto Calendar.json           # Original exported workflow
├── docker-compose.yml           # Local development setup
├── docker-entrypoint.sh         # Script that starts n8n and imports workflows
├── Dockerfile                   # Builds the n8n + workflow Docker image
├── readme.md                    # This file
├── render.yaml                  # Render deployment configuration
└── workflow.png                 # Workflow architecture diagram
```

### What Each File Does

| File | Purpose |
|------|---------|
| `Dockerfile` | Instructions to build a Docker image with n8n + your workflow |
| `docker-entrypoint.sh` | Startup script that launches n8n and auto-imports workflows |
| `docker-compose.yml` | Runs the project locally for testing |
| `.github/workflows/deploy.yml` | CI/CD pipeline: build → push → deploy |
| `workflows/Auto Calendar.json` | The workflow file that gets loaded into n8n |
| `.env.example` | Shows what environment variables are needed |
| `render.yaml` | Tells Render how to deploy the service |
| `.dockerignore` | Keeps the Docker image small by excluding unnecessary files |
| `.gitignore` | Prevents secrets and temp files from being committed |

---

## 🏗️ Workflow Architecture

### Main Components

- Telegram Trigger  
- Switch Node (Text / Voice handling)  
- Get File (for voice messages)  
- Gemini Transcription (voice to text)  
- Edit Fields (preprocessing)  
- AI Agent (intent detection + event extraction)  
- Google Calendar Nodes:
  - Create Event  
  - Delete Event  
  - Get Events  
  - Update Event  
- Telegram Send Message (confirmation)

---

## 🔄 Workflow Visual

![Workflow](workflow.png)

---

## 🧠 How It Works

### 1. User Input (Telegram)
- Accepts text messages
- Accepts voice messages (automatically transcribed)

### 2. AI Processing
The AI Agent:
- Detects user intent (create, update, delete, retrieve)
- Extracts:
  - Event title
  - Date and time
  - Duration
  - Attendees
  - Recurrence (if any)
- Converts relative dates (e.g., "tomorrow 9am", "next Monday")

### 3. Google Calendar Integration
Depending on the intent, the workflow:
- Creates a new event
- Updates an existing event
- Deletes an event
- Retrieves scheduled events

### 4. Confirmation
A structured confirmation message is sent back to the user via Telegram.

---

## 🛠️ Tech Stack

- n8n (Workflow Automation)
- Telegram Bot API
- Gemini (Chat Model + Audio Transcription)
- Google Calendar API
- OAuth2 Authentication
- Docker (Containerization)
- GitHub Actions (CI/CD)
- Render (Cloud Deployment)

---

## 🚀 CI/CD Pipeline — How It Works

This project uses a fully automated deployment pipeline. Here's what happens when you push code:

```
┌─────────────┐    ┌──────────────────┐    ┌─────────────┐    ┌──────────┐
│  Git Push    │───▶│  GitHub Actions   │───▶│  Docker Hub  │───▶│  Render   │
│ (main branch)│    │  (Build & Push)   │    │ (Image Store)│    │(Redeploy) │
└─────────────┘    └──────────────────┘    └─────────────┘    └──────────┘
```

### Step-by-Step Explanation

#### Step 1: You Push Code to GitHub
When you run `git push origin main`, GitHub detects the push and triggers the Actions workflow defined in `.github/workflows/deploy.yml`.

#### Step 2: GitHub Actions — Build Phase
A fresh Ubuntu virtual machine spins up and:
1. **Checks out your code** — Downloads your repository files
2. **Sets up Docker Buildx** — Prepares advanced Docker build tools
3. **Logs into Docker Hub** — Uses your `DOCKER_USERNAME` and `DOCKER_PASSWORD` from GitHub Secrets
4. **Builds the Docker image** — Reads the `Dockerfile`, creates an image with n8n + your workflow JSON
5. **Pushes the image** — Uploads it to Docker Hub with two tags:
   - `latest` (always points to the newest build)
   - The Git commit SHA (for version tracking)

#### Step 3: GitHub Actions — Deploy Phase
After the build succeeds:
1. **Calls the Render API** — Sends a POST request to `https://api.render.com/v1/services/{id}/deploys`
2. **Render pulls the new image** — Render fetches `your-username/n8n-calendar-automation:latest` from Docker Hub
3. **Render restarts the service** — The new container starts with the updated workflow

#### Step 4: n8n Starts Up
Inside the new container:
1. The `docker-entrypoint.sh` script runs
2. n8n starts in the background
3. The script waits for n8n to be ready
4. It imports all workflow JSON files from `/home/node/.n8n/workflows/`
5. Your Telegram Calendar workflow is now live!

---

## 🔧 Setup Guide

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed
- A [GitHub](https://github.com) account
- A [Docker Hub](https://hub.docker.com) account (free)
- A [Render](https://render.com) account (free tier works)

### Step 1: Clone and Configure Locally

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/calendar_automation.git
cd calendar_automation

# Create your local environment file
cp .env.example .env

# Edit .env and fill in your actual API keys
```

### Step 2: Test Locally with Docker Compose

```bash
# Build and start the container
docker-compose up --build

# Open n8n in your browser
# http://localhost:5678
```

### Step 3: Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets one by one:

| Secret Name | Where to Get It | What It's For |
|-------------|----------------|---------------|
| `DOCKER_USERNAME` | Your Docker Hub username | Logging into Docker Hub to push images |
| `DOCKER_PASSWORD` | Docker Hub → Account Settings → Security → New Access Token | Authenticating with Docker Hub |
| `RENDER_API_KEY` | Render Dashboard → Account Settings → API Keys | Triggering redeploys on Render |
| `RENDER_SERVICE_ID` | Render Dashboard → Your Service → Settings (in the URL: `srv-xxxxx`) | Identifying which Render service to redeploy |
| `OPENAI_API_KEY` | [OpenAI API Keys](https://platform.openai.com/api-keys) | AI features (if used) |
| `N8N_BASIC_AUTH_USER` | You choose this | Username to access n8n web UI |
| `N8N_BASIC_AUTH_PASSWORD` | You choose this | Password to access n8n web UI |



#### How to Create a Docker Hub Access Token
1. Go to [Docker Hub](https://hub.docker.com)
2. Click your profile → **Account Settings** → **Security**
3. Click **New Access Token**
4. Give it a name (e.g., "GitHub Actions")
5. Copy the token — use this as `DOCKER_PASSWORD`

#### How to Get Your Render API Key
1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click your profile → **Account Settings**
3. Scroll to **API Keys** → **Create API Key**
4. Copy the key — use this as `RENDER_API_KEY`

#### How to Find Your Render Service ID
1. Go to your Render Dashboard
2. Click on your service
3. Look at the URL: `https://dashboard.render.com/web/srv-xxxxxxxxxxxxx`
4. The `srv-xxxxxxxxxxxxx` part is your `RENDER_SERVICE_ID`

### Step 4: Set Up Render

#### Option A: Deploy from Docker Hub Image
1. Go to [Render Dashboard](https://dashboard.render.com) → **New** → **Web Service**
2. Select **Deploy an existing image from a registry**
3. Enter: `docker.io/YOUR_DOCKER_USERNAME/n8n-calendar-automation:latest`
4. Configure the service:
   - **Name:** `n8n-calendar-automation`
   - **Region:** Oregon (or closest to you)
   - **Plan:** Starter (or your preference)

#### Setting Environment Variables in Render
In the Render Dashboard for your service, go to **Environment** and add:

| Key | Value |
|-----|-------|
| `N8N_BASIC_AUTH_ACTIVE` | `true` |
| `N8N_BASIC_AUTH_USER` | Your chosen username |
| `N8N_BASIC_AUTH_PASSWORD` | Your chosen password |
| `N8N_PROTOCOL` | `https` |
| `N8N_HOST` | `your-service-name.onrender.com` |
| `WEBHOOK_URL` | `https://your-service-name.onrender.com` |
| `GENERIC_TIMEZONE` | `Asia/Kolkata` |
| `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | `true` |
| `TELEGRAM_BOT_TOKEN` | Your Telegram bot token |
| `GOOGLE_CLIENT_ID` | Your Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | Your Google OAuth client secret |
| `GEMINI_API_KEY` | Your Gemini API key |

> **💡 Tip:** Replace `your-service-name.onrender.com` with the actual URL Render gives your service.

### Step 5: Push and Deploy!

```bash
# Add all files
git add .

# Commit
git commit -m "Add CI/CD pipeline"

# Push to main — this triggers the pipeline!
git push origin main
```

Now go to your GitHub repository → **Actions** tab to watch the pipeline run!

---

## 🔐 Required Credentials

To run this workflow, configure the following in n8n:

- Telegram Bot Token
- Gemini API Key
- Google OAuth2 Credentials with Calendar scope

---

## ✅ Features

- Natural language event scheduling
- Voice message support
- Multi-turn conversational handling
- Relative date interpretation
- Full Google Calendar CRUD operations
- Real-time Telegram confirmations
- Automated CI/CD deployment pipeline
- Docker containerized for portability

---

## 🎯 Use Cases

- Personal scheduling assistant
- Conversational calendar management
- AI-based automation demo project
- Portfolio automation project

---

## 🔍 Troubleshooting

### Pipeline fails at "Log in to Docker Hub"
→ Check that `DOCKER_USERNAME` and `DOCKER_PASSWORD` are set correctly in GitHub Secrets.

### Pipeline fails at "Trigger Render redeploy"
→ Verify `RENDER_API_KEY` and `RENDER_SERVICE_ID` in GitHub Secrets. Make sure the Render service exists.

### n8n starts but workflow isn't loaded
→ Check the container logs in Render. The entrypoint script should show "Importing workflows..." messages.

### Workflow runs but Telegram/Google Calendar doesn't work
→ Check that all environment variables (API keys) are set in Render's Environment tab.

### Build is slow
→ The pipeline uses GitHub Actions caching. The first build is slow, but subsequent builds reuse cached layers.

---

## 📝 Making Changes

1. Edit your workflow in n8n
2. Export it as JSON
3. Replace `workflows/Auto Calendar.json` with the new export
4. Commit and push to `main`
5. The pipeline automatically builds, pushes, and deploys!