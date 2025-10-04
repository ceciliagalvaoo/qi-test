---
title: "Demo Guide"
sidebar_position: 6
---

# Demo Guide

## Project Overview

The Simple Fund (TSF) is a tokenized fund management platform that connects investors, fund managers, and consultants. The platform allows:

- **Investors**: Browse and invest in tokenized funds
- **Fund Managers**: Approve funds, users, and monitor platform activities
- **Consultants**: Create funds and manage client relationships

## How to Run Locally

### Prerequisites

Before running the application, make sure you have the following installed:
- Node.js (v16 or later)
- npm (v7 or later)
- Git

### Backend (API)

1. Clone the repository (if you haven't already):
   ```bash
   git clone https://github.com/MiguelClaret/Teambalaie.git
   cd Teambalaie
   ```

2. Navigate to the backend folder:
   ```bash
   cd apps/api
   ```

3. Install dependencies:
   ```bash
   npm install
   ```

4. Set up the database:
   ```bash
   # Create the database structure
   npx prisma migrate deploy
   
   # Generate Prisma client
   npx prisma generate
   ```

5. Seed the database with test data (optional but recommended):
   ```bash
   node scripts/seed-test-data.js
   ```

6. Start the backend server:
   ```bash
   npm run dev
   ```

The API will be available at `http://localhost:3000`. You can test it by accessing `http://localhost:3000/health` in your browser, which should return a status indicating the API is running.

### Frontend (Web)

1. Open a new terminal window and navigate to the frontend folder from the project root:
   ```bash
   cd apps/web
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

4. Open your browser and visit:
   ```
   http://localhost:5173
   ```

### Demo Accounts

The application comes with pre-configured demo accounts you can use:

| Role | Email | Password |
|------|-------|----------|
| Consultant | consultor@vero.com | 123456 |
| Fund Manager | gestor@vero.com | 123456 |
| Investor | investidor@vero.com | 123456 |

## Deployed Demo

You can also access the deployed version without setting up locally:

👉 [https://the-simple-fund-7kbnhjy0v-miguelclarets-projects.vercel.app](https://the-simple-fund-7kbnhjy0v-miguelclarets-projects.vercel.app)

The deployed version contains the same features and demo accounts as the local setup. It's ideal for quickly exploring the platform without installation.
