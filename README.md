# StoreScorer v2

AI-powered e-commerce store audit platform built with the Licenzr Build Standard.

## Tech Stack

- **Framework**: Next.js 15.1.6 (App Router)
- **Database**: PostgreSQL 16 via direct functions (no ORM)
- **Auth**: Clerk
- **Payments**: Stripe
- **Styling**: Tailwind CSS
- **Validation**: Zod

## Architecture

```
API Route → TypeScript Wrapper → callFunction<T>() → PostgreSQL Function → JSONB
```

All database operations go through PostgreSQL functions with full audit logging.

## Getting Started

### Prerequisites

- Node.js 20+
- Docker & Docker Compose
- PostgreSQL 16 (via Docker)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/SlabStak/StoreScorer-v2.git
cd StoreScorer-v2
```

2. Install dependencies:
```bash
npm install
```

3. Copy environment file:
```bash
cp .env.example .env.local
```

4. Start database:
```bash
docker compose up -d postgres redis
```

5. Run database setup:
```bash
./scripts/setup-db.sh
```

6. (Optional) Seed development data:
```bash
./scripts/reset-and-seed.sh
```

7. Start development server:
```bash
npm run dev
```

## Environment Variables

See `.env.example` for required environment variables:

- `DATABASE_URL` - PostgreSQL connection string
- `CLERK_SECRET_KEY` - Clerk authentication
- `STRIPE_SECRET_KEY` - Stripe payments
- `OPENAI_API_KEY` - AI analysis

## Project Structure

```
├── postgresql/
│   ├── functions/     # PostgreSQL functions (one per domain)
│   ├── seed/          # Development seed data
│   └── setup-api-user.sql
├── sql/migrations/    # Database migrations
├── src/
│   ├── app/api/       # API routes
│   ├── lib/db/        # TypeScript database wrappers
│   └── types/         # TypeScript types
├── scripts/           # Database scripts
└── docker-compose.yml
```

## API Routes

| Route | Method | Description |
|-------|--------|-------------|
| `/api/health` | GET | Health check |
| `/api/checkout` | POST | Create audit & Stripe session |
| `/api/audit/[id]` | GET | Get audit details |
| `/api/reviews` | POST | Submit review |
| `/api/testimonials` | GET | Get public testimonials |
| `/api/share/[token]` | GET | Get shared report |
| `/api/webhook/stripe` | POST | Stripe webhook |

## License

MIT
