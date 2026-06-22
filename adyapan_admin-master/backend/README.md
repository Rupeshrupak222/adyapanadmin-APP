# Adyapan Admin Backend

Backend server for the Adyapan Admin Flutter app. Built with **Node.js + Express + Prisma ORM + TiDB Cloud**.

## Tech Stack
- **Runtime:** Node.js
- **Framework:** Express.js
- **ORM:** Prisma
- **Database:** TiDB Cloud (MySQL compatible)

## Setup Instructions

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
Copy `.env.example` to `.env` and fill in your TiDB credentials:
```bash
cp .env.example .env
```

Edit `.env`:
```
DATABASE_URL="mysql://YOUR_USER:YOUR_PASSWORD@YOUR_HOST:4000/adyapan_db?sslaccept=strict"
```

### 3. Push Schema to Database
```bash
npx prisma db push
```

### 4. Seed Initial Data
```bash
npm run seed
```

### 5. Start Server
```bash
# Development (with hot reload)
npm run dev

# Production
npm start
```

Server runs on `http://localhost:3000`

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET/POST/PUT/DELETE | `/api/v1/students` | Students CRUD |
| GET/POST/PUT/DELETE | `/api/v1/teachers` | Teachers CRUD |
| GET/POST/PUT/DELETE | `/api/v1/schools` | Schools CRUD |
| GET/POST/PUT/DELETE | `/api/v1/live-classes` | Live Classes |
| GET/POST/DELETE | `/api/v1/events` | System Events |
| GET/POST/PUT/DELETE | `/api/v1/leaves` | Leave Requests |
| GET/POST/PUT | `/api/v1/meetings` | Meetings |

## Database Models
- **School** — Partner schools with principal & location
- **Student** — Full student profile with grades, attendance, skills
- **Teacher** — Educator profile with syllabus progress, doubts
- **LiveClass** — Real-time classroom sessions
- **SystemEvent** — Activity feed / audit log
- **LeaveRequest** — Teacher leave applications
- **Meeting** — Faculty meeting records

## Prisma Commands
```bash
npx prisma generate    # Regenerate client after schema changes
npx prisma db push     # Push schema to TiDB
npx prisma studio      # Open visual database browser
```

## Project Structure
```
adyapan_backend/
├── prisma/
│   ├── schema.prisma    ← Database schema
│   └── seed.js          ← Initial data seeder
├── src/
│   ├── index.js         ← Express server entry
│   ├── lib/prisma.js    ← Prisma client singleton
│   └── routes/
│       ├── students.js
│       ├── teachers.js
│       ├── schools.js
│       ├── liveClasses.js
│       ├── events.js
│       ├── leaves.js
│       └── meetings.js
├── .env.example         ← Environment template
└── package.json
```

## Connected Frontend
This backend serves the [Adyapan Admin Flutter App](https://github.com/kapish78910/adyapan_admin).
The Flutter app calls `http://localhost:3000/api/v1/*` endpoints.
