Simple Node.js backend example to expose SQL Server data to the Flutter app.

Setup
1. Install dependencies:

   npm install

2. Copy `.env.example` to `.env` and update values (do not commit `.env`).

3. Run the server:

   npm start

Endpoints
- GET /health  -> checks DB connectivity
- GET /tables  -> lists tables in the configured database

Security
- Keep credentials out of source control. Run the backend on a secure internal network or behind a firewall.
